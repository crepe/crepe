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
      routes: [],
      vendor: nil,
      version: nil
    )

    class << self

      attr_reader :config

      def inherited subclass
        subclass.config = config.dup
      end

      def namespace path, options = {}, &block
        return config.update options.merge(namespace: path) unless block

        outer_helper = config[:helper]
        config.with options.merge(
          namespace: path,
          endpoint: Util.deep_dup(config[:endpoint]),
          helper: Helper.new { include outer_helper }
        ), &block
      end
      alias_method :resource, :namespace

      def param name, options = {}, &block
        namespace "/:#{name}", options, &block
      end

      def vendor vendor
        config[:endpoint][:vendor] = vendor
      end

      def version version, &block
        namespace version, version: version, &block
      end

      def use middleware, *args, &block
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

      def rescue_from exception, options = {}, &block
        config[:endpoint][:rescuers] << {
          exception_class: exception, options: options, block: block
        }
      end

      Endpoint.default_config[:callbacks].each_key do |type|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
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

      def helper mod = nil, &block
        if block
          warn 'block takes precedence over module' if mod
          mod = Module.new(&block)
        end
        config[:helper].send :include, mod
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

      def stream *args, &block
        get(*args) { stream { instance_eval(&block) } }
      end

      def route method, path = '/', options = {}, &block
        block ||= proc { head :ok }
        options = config[:endpoint].merge(handler: block).merge options
        endpoint = Endpoint.new(options).extend config[:helper]
        mount endpoint, (options[:conditions] || {}).merge(
          at: path, method: method, anchor: true
        )
      end

      def mount app, options = {}
        path = '/'

        if options.key? :at
          path = options.delete :at
        elsif app.is_a? Hash
          options = app
          app, path = options.find { |k, v| k.respond_to? :call }
          options.delete app if app
        end

        method = options.delete :method
        method = %r{#{method.join '|'}}i if method.respond_to? :join

        path_info = mount_path path, options
        conditions = { path_info: path_info, request_method: method }

        defaults = { format: config[:endpoint][:formats].first }
        defaults[:version] = config[:version].to_s if config[:version]

        config[:routes] << [app, conditions, defaults]
      end

      def to_app options = {}
        exclude = options.fetch(:exclude, [])
        middleware = config[:middleware] - exclude

        generate_options_routes!

        route_set = Rack::Mount::RouteSet.new
        config[:routes].each do |app, conditions, defaults|
          if app.is_a?(Class) && app.ancestors.include?(API)
            app = app.to_app exclude: exclude | middleware
          end
          route_set.add_route app, conditions, defaults
        end
        route_set.freeze

        Rack::Builder.app do
          middleware.each { |ware, args, block| use ware, *args, &block }
          run route_set
        end
      end

      protected

        attr_writer :config

      private

        def app
          @app ||= to_app
        end

        def mount_path path, conditions
          return path if path.is_a? Regexp

          namespaces = config.all(:namespace).compact
          separator = conditions.delete(:separator) { %w[ / . ? ] }
          anchor = conditions.delete(:anchor) { false }

          path = Util.normalize_path ['/', namespaces, path].join '/'
          path << '(.:format)' if anchor

          Rack::Mount::Strexp.compile path, conditions, separator, anchor
        end

        def generate_options_routes!
          paths = config[:routes].group_by { |_, cond| cond[:path_info] }
          paths.each do |path, routes|
            allowed = routes.map { |_, cond| cond[:request_method] }
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

  end
end
