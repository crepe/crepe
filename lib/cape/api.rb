require 'rack/mount'

module Cape
  class API

    @running = false

    @config = {
      after:      [
        Endpoint::Pagination,
        Endpoint::Rendering
      ],
      before:     [
        Endpoint::Acceptance
      ],
      endpoints:  [],
      formats:    %w[json],
      helpers:    [],
      middleware: [
        Rack::Runtime,
        Middleware::ContentNegotiation,
        Middleware::RestfulStatus,
        Middleware::Head,
        Rack::ConditionalGet,
        Rack::ETag
      ],
      rescuers:   [],
      vendor:     'cape'
    }

    class << self

      attr_reader :config

      def running?
        @running
      end

      def running!
        @running = true
      end

      def inherited subclass
        subclass.config = config.inject({}) { |hash, (key, value)|
          hash[key] = value.dup
          hash
        }
      end

      def vendor vendor
        config[:vendor] = vendor
      end

      def version version, &block
        config[:version] = version
        if block_given?
          instance_eval &block
          config.delete :version
        end
      end

      def use middleware, *args
        config[:middleware] << [middleware, *args]
      end

      def respond_to *formats
        config[:formats].concat formats.map(&:to_s)
      end

      def rescue_from exception, options = {}, &block
        config[:rescuers] << {
          class_name: exception.name, options: options, block: block
        }
      end

      def before_filter mod = nil, &block
        filter = block || mod
        config[:before] << filter if filter
      end

      def after_filter mod = nil, &block
        filter = block || mod
        config[:after] << filter if filter
      end

      def helper mod = nil, &block
        if block_given?
          warn 'block takes precedence over module' if mod
          mod = Module.new &block
        end
        unless mod.is_a? Module
          raise ArgumentError, 'block or module required'
        end
        config[:helpers] << mod
      end

      def call env
        app.call env
      end

      %w[get post put patch delete].each do |method|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{method} *args, &block
            route '#{method.upcase}', *args, &block
          end
        RUBY
      end

      def route method, path, options = {}, &block
        config[:endpoints] << options.merge(
          handler: block,
          conditions: (options[:conditions] || {}).merge(
            at: "#{path}(.:format)", method: method, anchor: true
          )
        )
      end

      def mount app, options = nil
        if options
          path = options.delete :at
        else
          options = app
          app, path = options.find { |k, v| k.respond_to? :call }
          options.delete app if app
        end

        path = mount_path path, options
        method = options.delete :method
        conditions = { path_info: path, request_method: method }

        defaults = { format: config[:formats].first }
        defaults[:version] = config[:version].to_s if config[:version]

        routes.add_route app, conditions, defaults
      end

      protected

        attr_writer :config

      private

        def app
          @app ||= begin
            global_options = config.slice(
              :after, :before, :formats, :helpers, :rescuers, :vendor
            )
            config[:endpoints].each do |route|
              endpoint = Endpoint.new Util.deeper_merge(global_options, route)
              mount endpoint, route[:conditions]
            end
            routes.freeze

            if Cape::API.running?
              app = routes
            else
              builder = Rack::Builder.new
              config[:middleware].each do |middleware|
                builder.use *middleware
              end
              builder.run routes
              app = builder.to_app
              Cape::API.running!
            end

            app
          end
        end

        def routes
          @routes ||= Rack::Mount::RouteSet.new
        end

        def mount_path path, requirements
          path = "/#{config[:version]}/#{path}"
          path.squeeze! '/'
          path.sub! %r{/+\Z}, ''
          path = '/' if path.empty?

          separator = requirements.delete(:separator) { %w[ / . ? ] }
          anchor = requirements.delete(:anchor) { false }

          Rack::Mount::Strexp.compile path, requirements, separator, anchor
        end

    end

  end
end
