require 'rack/mount'

module Crepe
  # The API class provides a DSL to build a collection of endpoints.
  class API

    # Module class that is instantiated and stores an API's helper methods.
    # Supports dynamic extensibility via {Util::ChainedInclude}, ensuring that
    # helpers defined after endpoints are still accessible to those endpoints.
    class Helper < Module
      include Util::ChainedInclude
    end

    METHODS = %w[GET POST PUT PATCH DELETE]

    SEPARATORS = %w[/ . ?]

    @config = Util::HashStack.new(
      endpoint: Endpoint.default_config,
      helper: Helper.new,
      middleware: [
        Middleware::ContentNegotiation,
        Middleware::RestfulStatus,
        Middleware::Head,
        Rack::ConditionalGet,
        Rack::ETag
      ],
      namespace: nil,
      route_options: {
        constraints: {},
        defaults: {},
        anchor: false,
        separators: SEPARATORS
      },
      version: nil
    )

    class << self

      attr_reader :config

      def routes
        @routes ||= []
      end

      def inherited subclass
        subclass.config = config.dup
      end

      def scope namespace = nil, **options, &block
        return config.update options.merge(namespace: namespace) unless block

        outer_helper = config[:helper]
        config.with options.merge(
          namespace: namespace,
          route_options: normalize_route_options(options),
          endpoint: Util.deep_dup(config[:endpoint]),
          helper: Helper.new { include outer_helper }
        ), &block
      end
      alias namespace scope
      alias resource scope

      def param name = nil, **options, &block
        name ||= options.keys.first
        namespace "/:#{name}", options, &block
      end

      def vendor vendor
        config[:endpoint][:vendor] = vendor
      end

      def version version, &block
        if config[:version] || config[:namespace]
          raise ArgumentError, "can't nest versions"
        end
        scope version, version: version, &block
      end

      def use middleware, *args, &block
        if config[:namespace]
          raise ArgumentError, "can't nest middleware in a namespace"
        end
        config[:middleware] << [middleware, args, block]
      end

      def respond_to *formats
        config[:endpoint][:formats] = []

        formats.each do |format|
          if format.respond_to? :each_pair
            format.each_pair do |f, renderer|
              config[:endpoint][:formats] << f.to_sym
              config[:endpoint][:renderers][f.to_sym] = renderer
            end
          else
            config[:endpoint][:formats] << format.to_sym
          end
        end
      end

      def rescue_from exception, with: nil, &block
        warn 'block takes precedence over handler' if block && with
        handler = block || with
        raise ArgumentError, 'block or handler required' unless handler
        config[:endpoint][:rescuers][exception] = handler
      end

      def define_callback type
        config[:endpoint][:callbacks][type] ||= []

        instance_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{type} filter = nil, &block
            warn 'block takes precedence over object' if block && filter
            callback = block || filter
            raise ArgumentError, 'block or filter required' unless callback
            config[:endpoint][:callbacks][:#{type}] << callback
          end

          def skip_#{type} filter = nil, &block
            warn 'block takes precedence over object' if block && filter
            callback = block || proc { |c| filter == c || filter === c }
            raise ArgumentError, 'block or filter required' unless callback
            config[:endpoint][:callbacks][:#{type}].delete_if(&callback)
          end
        RUBY
      end

      def basic_auth *args, &block
        skip_before Filter::BasicAuth
        before Filter::BasicAuth.new(*args, &block)
      end

      def helper mod = nil, prepend: false, &block
        if block
          warn 'block takes precedence over module' if mod
          mod = Module.new(&block)
        end
        method = prepend ? :prepend : :include
        config[:helper].send method, mod
      end

      def call env
        app.call env
      end

      METHODS.each do |method|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{method.downcase} *args, &block
            route '#{method}', *args, &block
          end
        RUBY
      end

      def any *args, &block
        route nil, *args, &block
      end

      def route method, path = '/', **options, &block
        block ||= proc { head }
        endpoint = Endpoint.new config[:endpoint], &block
        endpoint.extend config[:helper]
        mount endpoint, options.merge(at: path, method: method, anchor: true)
      end

      def mount app = nil, **options
        path = '/'

        if app && options.key?(:at)
          path = options.delete :at
        elsif app.nil?
          app, path = options.find { |k, v| k.respond_to? :call }
          options.delete app if app
        end

        if app.respond_to? :extend_endpoints!
          app.extend_endpoints! config[:endpoint]
        end

        method = options.delete :method
        method = %r{#{method.join '|'}}i if method.respond_to? :join

        options = normalize_route_options options

        conditions = {
          path_info: mount_path(path, options), request_method: method
        }

        defaults = options[:defaults]
        defaults[:format] = config[:endpoint][:formats].first
        defaults[:version] = config[:version] if config[:version]

        routes << [app, conditions, defaults]
      end

      def to_app(exclude: [])
        middleware = config[:middleware] - exclude

        generate_options_routes!

        route_set = Rack::Mount::RouteSet.new
        routes.each do |app, conditions, defaults|
          if app.is_a?(Class) && app.ancestors.include?(API)
            app = app.to_app exclude: exclude | middleware
          end
          route_set.add_route app, conditions, defaults
        end
        route_set.freeze

        Rack::Builder.app do
          middleware.each { |m, args, block| use m, *args, &block }
          run route_set
        end
      end

      def endpoints
        routes.map(&:first).select { |app| app.is_a? Endpoint }
      end

      def extend_endpoints! config
        endpoints.each do |e|
          e.config.update Util.deeper_merge config, e.config
        end
      end

      protected

        attr_writer :config

      private

        def app
          @app ||= to_app
        end

        def normalize_route_options options
          options = Util.deeper_merge config[:route_options], options
          options.except(*config[:route_options].keys).each_key do |key|
            value = options.delete key
            option = value.is_a?(Regexp) ? :constraints : :defaults
            options[option][key] = value
          end
          options
        end

        def mount_path path, options
          return path if path.is_a? Regexp

          namespaces = config.all(:namespace).compact
          path = Util.normalize_path ['/', namespaces, path].join '/'
          path << '(.:format)' if options[:anchor]
          Rack::Mount::Strexp.compile(
            path, *options.values_at(:constraints, :separators, :anchor)
          )
        end

        def generate_options_routes!
          paths = routes.group_by { |_, cond| cond[:path_info] }
          paths.each do |path, options|
            allowed = options.map { |_, cond| cond[:request_method] }
            next if allowed.include?('OPTIONS') || allowed.none?

            allowed << 'HEAD' if allowed.include? 'GET'
            allowed << 'OPTIONS'
            allowed.sort!

            route 'OPTIONS', path do
              headers['Allow'] = allowed.join ', '
              { allow: allowed }
            end
            route METHODS - allowed, path do
              headers['Allow'] = allowed.join ', '
              error! :method_not_allowed, allow: allowed
            end
          end
        end

    end

    define_callback :before
    define_callback :after

  end
end
