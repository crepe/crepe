require 'rack/mount'

module Cape
  class API

    @settings = {
      :formats    => %w[json],
      :helpers    => [],
      :middleware => [
        Cape::Middleware::Format,
        Cape::Middleware::Pagination
      ],
      :rescuers   => [],
      :endpoints  => []
    }

    class << self

      attr_reader :settings

      def inherited subclass
        subclass.settings = settings.inject({}) { |hash, (key, value)|
          hash[key] = value.dup
          hash
        }
      end

      def version name, options = {}, &block
        settings[:version] = options.merge(:name => name)
        if block_given?
          instance_eval &block
          settings.delete :version
        end
      end

      def respond_to *formats
        settings[:formats].concat formats
      end

      def use middleware, *args
        settings[:middleware] << [middleware, *args]
      end

      def rescue_from exception, options = {}, &block
        settings[:rescuers] << {
          :class_name => exception.name, :options => options, :block => block
        }
      end

      def helper mod = nil, &block
        if block_given?
          warn 'block takes precedence over module' if mod
          mod = Module.new &block
        end
        unless mod.is_a? Module
          raise ArgumentError, 'module or block required'
        end
        settings[:helpers] << mod
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

      def route method, path, requirements = {}, &block
        settings[:endpoints] << {
          :handler => block, :options => requirements.merge(
            :at => "#{path}(.:format)", :method => method, :anchor => true
          )
        }
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

      attr_writer :settings

      private

      def app
        @app ||= begin
          settings[:endpoints].each do |route|
            mount build_endpoint(route[:handler]), route[:options]
          end
          app = Rack::Builder.new do
            use Rack::Deflater
            use Rack::ETag
            use Cape::Middleware::ContentNegotiation
            use Cape::Middleware::Head
            use Cape::Middleware::RestfulStatus
          end
          app.run routes.freeze
          app.to_app
        end
      end

      def routes
        @routes ||= Rack::Mount::RouteSet.new
      end

      def mount_path path, requirements
        version = settings[:version] && settings[:version][:name]

        path = "/#{version}/#{path}"
        path.squeeze! '/'
        path.sub! %r{/+\Z}, ''
        path = '/' if path.empty?

        separator = requirements.delete(:separator) { %w[ / . ? ] }
        anchor = requirements.delete(:anchor) { false }

        Rack::Mount::Strexp.compile path, requirements, separator, anchor
      end

      def default_format
        settings[:formats].first
      end

      def build_endpoint handler
        app = Endpoint.new(
          :handler        => handler,
          :default_format => default_format,
          :formats        => settings[:formats],
          :helpers        => settings[:helpers],
          :rescuers       => settings[:rescuers],
          :version        => settings[:version]
        )

        builder = Rack::Builder.new

        settings[:middleware].each { |middleware| builder.use *middleware }

        helpers = settings[:helpers]
        app.extend *helpers unless helpers.empty?

        builder.run app
        builder.to_app
      end

    end

  end
end
