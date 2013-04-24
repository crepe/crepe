require 'rack/mount'

module Crepe
  # The API class provides a DSL to build a collection of endpoints.
  class API

    METHODS = %w[GET POST PUT PATCH DELETE]

    SEPARATORS = %w[ / . ? ]

    @config = Config.new(
      endpoint: Endpoint.default_config,
      helper: Module.new,
      middleware: [
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
      version: {
        name: 'v',
        with: :path
      }
    )

    @routes = []

    class << self

      attr_reader :config

      attr_reader :routes

      def inherited subclass
        subclass.config = config.deep_dup
        subclass.config[:helper] = config[:helper].dup
        subclass.routes = routes.dup
      end

      def scope namespace = nil, **scoped, &block
        scoped = scoped.merge(
          helper: config[:helper].dup,
          namespace: namespace,
          route_options: normalize_route_options(scoped)
        )
        config.scope scoped, &block
      end
      alias namespace scope
      alias resource scope

      def param name = nil, **options, &block
        name ||= options.keys.first
        namespace "/:#{name}", options, &block
      end

      def version level = nil, **options, &block
        with = options.fetch :with, config[:version][:with]
        path = level if with == :path
        scope path, version: options.merge(level: level, with: with), &block
      end

      def use middleware, *args, &block
        if config[:namespace]
          raise ArgumentError, "can't nest middleware in a namespace"
        end
        config[:middleware] << [middleware, args, block]
      end

      def respond_to *formats, **renderers
        config[:endpoint][:formats] = formats | renderers.keys
        renderers.each { |format, renderer| render format, with: renderer }
      end

      def render *formats, **options
        renderer = options.fetch :with
        formats.each { |f| config[:endpoint][:renderers][f] = renderer }
      end

      def parse *media_types, **options
        parser = options.fetch :with
        media_types = Util.media_types media_types
        media_types.each { |t| config[:endpoint][:parsers][t] = parser }
      end

      def rescue_from *exceptions, with: nil, &block
        warn 'block takes precedence over handler' if block && with
        handler = block || with
        raise ArgumentError, 'block or handler required' unless handler
        exceptions.each { |e| config[:endpoint][:rescuers][e] = handler }
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

      def let name, &block
        if Endpoint.method_defined? name
          raise ArgumentError, "can't redefine Crepe::Endpoint##{name}"
        end
        helper do
          module_eval { define_method "_eval_#{name}", &block }
          module_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{name} *args
              return @_memo_#{name}[args] if (@_memo_#{name} ||= {}).key? args
              @_memo_#{name}[args] = _eval_#{name}(*args)
            end
          RUBY
        end
      end

      def call env
        app.call env
      end

      METHODS.each do |method|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{method.downcase} *args, &block # def get *args, &block
            route '#{method}', *args, &block   #   route 'GET', *args, &block
          end                                  # end
        RUBY
      end

      def any *args, &block
        route nil, *args, &block
      end

      def route method, path = '/', **options, &block
        block ||= proc { head }
        endpoint = Endpoint.new(&block)
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

        method = options.delete :method
        method = %r{#{method.join '|'}}i if method.respond_to? :join

        options = normalize_route_options options

        conditions = {
          path_info: mount_path(path, options), request_method: method
        }
        if level = config[:version][:level]
          case config[:version][:with]
            when :query  then conditions[:query_version] = /\A#{level}\Z/
            when :header then conditions[:header_versions] = /\A#{level}\Z/
          end
        end

        defaults = options[:defaults]
        defaults[:format] = config[:endpoint][:formats].first

        routes << [app, conditions, defaults, config.dup]
      end

      def to_app(exclude: [])
        middleware = config.all(:middleware) - exclude

        route_set = Rack::Mount::RouteSet.new request_class: request_class
        configured_routes(exclude: exclude | middleware).each do |route|
          route_set.add_route(*route)
        end
        route_set.freeze

        Rack::Builder.app do
          middleware.each { |m, args, block| use m, *args, &block }
          run route_set
        end
      end

      protected

        attr_writer :config, :routes

      private

        def app
          @app ||= to_app
        end

        def normalize_route_options options
          options = options.except(*config.keys)
          options = Util.deep_merge config[:route_options], options
          options.except(*config[:route_options].keys).each_key do |key|
            value = options.delete key
            option = value.is_a?(Regexp) ? :constraints : :defaults
            options[option][key] = value
          end
          options
        end

        def mount_path path, options
          return path if path.is_a? Regexp

          path = Util.normalize_path [*config.all(:namespace), path].join '/'
          path << '(.:format)' if options[:anchor]
          Rack::Mount::Strexp.compile(
            path, *options.values_at(:constraints, :separators, :anchor)
          )
        end

        def request_class
          Request.dup.tap { |r| r.config = config }
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

        def configured_routes(exclude: [])
          generate_options_routes!

          routes.map do |app, conditions, defaults, config|
            if app.is_a?(Class) && app.ancestors.include?(API)
              app = Class.new(app).to_app exclude: exclude
            elsif app.is_a?(Endpoint)
              app = app.dup
              app.configure! config.to_h[:endpoint]
              config.all(:helper).each { |helper| app.extend helper }
            end

            [app, conditions, defaults]
          end
        end

    end

    define_callback :before
    define_callback :after

  end
end
