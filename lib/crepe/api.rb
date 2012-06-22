require 'rack/mount'

module Crepe
  class API

    @settings = {
      :formats    => %w[json],
      :helpers    => [],
      :middleware => [
        Rack::Deflater,
        Rack::ETag,
        Crepe::Middleware::Format,
        Crepe::Middleware::Head,
        Crepe::Middleware::Pagination,
        Crepe::Middleware::RestfulStatus
      ],
      :prefix     => '/',
      :rescuers   => []
    }

    class << self

      attr_reader :settings

      def inherited subclass
        subclass.settings = settings.inject({}) { |hash, (key, value)|
          hash[key] = value.dup
          hash
        }
      end

      def prefix *prefix
        settings[:prefix] = prefix.first unless prefix.empty?
        settings[:prefix]
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
        mod = Module.new &block if block_given?
        raise ArgumentError, "module or block required" unless mod.is_a? Module
        settings[:helpers] << mod
      end

      def call env
        routes.freeze.call env
      end

      %w[get post put patch delete].each do |method|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{method} *args, &block
            route '#{method.upcase}', *args, &block
          end
        RUBY
      end

      def route method, path, requirements = {}, &block
        endpoint = build_endpoint block
        mount endpoint, requirements.merge(
          :at => path, :method => method, :anchor => true
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

        anchor = options.delete(:anchor) { false }
        path = mount_path path, options, anchor

        method = options.delete(:method)
        method = nil if method == :any

        routes.add_route app, :path_info => path, :request_method => method
      end

      protected

      attr_writer :settings

      private

      def routes
        @routes ||= Rack::Mount::RouteSet.new
      end

      def mount_path path, requirements, anchor = false
        version = settings[:version] && settings[:version][:name]
        path = [prefix, version.to_s, path].join '/'
        path.squeeze! '/'
        path.sub! %r{/+\Z}, ''
        path = '/' if path.empty?
        separator = requirements.delete(:separator) { %w[ / . ? ] }
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
          :prefix         => settings[:prefix],
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
