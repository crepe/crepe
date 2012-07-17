require 'rack/mount'

module Crepe
  class API

    @running = false

    @config = {
      :after      => [
        Endpoint::Pagination,
        Endpoint::Rendering
      ],
      :before     => [],
      :endpoints  => [],
      :formats    => %w[json],
      :helpers    => [],
      :middleware => [
        Rack::Runtime,
        Middleware::ContentNegotiation,
        Middleware::RestfulStatus,
        Middleware::Head,
        Rack::ConditionalGet,
        Rack::ETag
      ],
      :rescuers   => []
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

      def version name, options = {}, &block
        config[:version] = options.merge(:name => name)
        if block_given?
          instance_eval &block
          config.delete :version
        end
      end

      def respond_to *formats
        config[:formats].concat formats
      end

      def use middleware, *args
        config[:middleware] << [middleware, *args]
      end

      def rescue_from exception, options = {}, &block
        config[:rescuers] << {
          :class_name => exception.name, :options => options, :block => block
        }
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
          :handler => block,
          :conditions => (options[:conditions] || {}).merge(
            :at => "#{path}(.:format)", :method => method, :anchor => true
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

        routes.add_route app, :path_info => path, :request_method => method
      end

      protected

        attr_writer :config

      private

        def app
          @app ||= begin
            config[:endpoints].each do |route|
              endpoint = Endpoint.new route.merge(
                config.slice(
                  :after, :before, :formats, :helpers, :rescuers, :version
                )
              )
              mount endpoint, route[:conditions]
            end
            routes.freeze

            if Crepe::API.running?
              app = routes
            else
              builder = Rack::Builder.new
              config[:middleware].each do |middleware|
                builder.use *middleware
              end
              builder.run routes
              app = builder.to_app
              Crepe::API.running!
            end

            app
          end
        end

        def routes
          @routes ||= Rack::Mount::RouteSet.new
        end

        def mount_path path, requirements
          version = config[:version] && config[:version][:name]

          path = "/#{version}/#{path}"
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
