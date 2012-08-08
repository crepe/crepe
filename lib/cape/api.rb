require 'active_support/core_ext/hash/deep_dup'
require 'rack/mount'

module Cape
  class API

    class Helper < Module
      include Util::ChainedInclude
    end

    @running = false

    @config = Util::HashStack.new(
      routes: [],
      endpoint: Endpoint.default_config,
      helper: Helper.new,
      middleware: [
        Rack::Runtime,
        Middleware::ContentNegotiation,
        Middleware::RestfulStatus,
        Middleware::Head,
        Rack::ConditionalGet,
        Rack::ETag
      ],
      namespace: nil,
      vendor: nil,
      version: nil
    )

    class << self

      attr_reader :config

      def running?
        @running
      end

      def running!
        @running = true
      end

      def inherited subclass
        subclass.config = Util.deep_dup config
      end

      def namespace path, options = {}, &block
        if block
          config.with namespaced_config(path, options), &block
        else
          config[:namespace] = path
        end
      end
      alias_method :resource, :namespace

      def param name, &block
        namespace "/:#{name}", &block
      end

      def vendor vendor
        config[:endpoint][:vendor] = vendor
      end

      def version version, &block
        config.with version: version do
          namespace version, &block
        end
      end

      def use middleware, *args
        config[:middleware] << [middleware, *args]
      end

      def respond_to *formats
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
          class_name: exception.name, options: options, block: block
        }
      end

      def before_filter mod = nil, &block
        warn 'block takes precedence over module' if block && mod
        filter = block || mod
        config[:endpoint][:before_filters] << filter if filter
      end

      def after_filter mod = nil, &block
        warn 'block takes precedence over module' if block && mod
        filter = block || mod
        config[:endpoint][:after_filters] << filter if filter
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

      %w[get post put patch delete].each do |method|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{method} *args, &block
            route '#{method.upcase}', *args, &block
          end
        RUBY
      end

      def any *args, &block
        route nil, *args, &block
      end

      def route method, path = '/', options = {}, &block
        options = config[:endpoint].merge(handler: block).merge options
        endpoint = Endpoint.new(options).extend config[:helper]
        mount endpoint, (options[:conditions] || {}).merge(
          at: path, method: method, anchor: true
        )
      end

      def mount app, options = nil
        if options
          path = options.delete(:at) { '/' }
        else
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

      protected

        attr_writer :config

      private

        def namespaced_config namespace, options = {}
          parent_helper = config[:helper]
          options.merge(
            namespace: namespace,
            endpoint: Util.deep_dup(config[:endpoint]),
            helper: Helper.new { include parent_helper }
          )
        end

        def app
          @app ||= begin
            routes = Rack::Mount::RouteSet.new
            config[:routes].each { |route| routes.add_route *route }
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

        def mount_path path, conditions
          namespaces = config.all(:namespace).compact
          separator = conditions.delete(:separator) { %w[ / . ? ] }
          anchor = conditions.delete(:anchor) { false }

          path = '/' + [namespaces, path].flatten.join('/')
          path.squeeze! '/'
          path.sub! %r{/+\Z}, ''
          path = '/' if path.empty?
          path << '(.:format)' if anchor

          Rack::Mount::Strexp.compile path, conditions, separator, anchor
        end

    end

  end
end
