require 'rack/mount'

module Crepe
  # The API class provides a DSL to build a collection of endpoints.
  class API

    METHODS = %w[GET POST PUT PATCH DELETE]

    SEPARATORS = %w[ / . ? ]

    @config = Config.new(
      endpoint: Endpoint,
      middleware: [
        Middleware::JSCallback,
        Middleware::RestfulStatus,
        Middleware::Head,
        Rack::ConditionalGet,
        Rack::ETag
      ],
      namespace: nil,
      route_options: {
        constraints: {},
        defaults: {},
        separators: SEPARATORS,
        anchor: false
      },
      version: {
        name: 'v',
        with: :path
      }
    )

    @routes = []

    class << self

      # @return [Array] uncompiled routes
      attr_reader :routes

      # The base DSL method of a Crepe API, +route+ defines an API route by
      # method(s), path, options, and a block that is evaluated at runtime.
      #
      #   route 'GET', '/' do
      #     { message: 'Hello, world!' }
      #   end
      #   # renders {"message":"Hello, world!"}
      #
      # Common HTTP verbs (GET, POST, PUT, PATCH, DELETE) are aliased to their
      # own methods, and the path defaults to a forward slash, so the above can
      # be simplified:
      #
      #   get do
      #     { message: 'Hello, world!' }
      #   end
      #
      # Crepe routing should be familiar to anyone who has used Rails or
      # Sinatra. Named path parameters are prefixed with +:+, and are
      # accessible via the +params+ hash.
      #
      #   get '/hello/:name' do
      #     { message: "Hello, #{params[:name]}" }
      #   end
      #
      # Routes take the following options:
      #
      # - <tt>:constraints</tt>: a hash of parameter names and their
      #   constraints (that is, requirements for the route to resolve, usually
      #   in the form of regular expressions)
      #
      # - <tt>:defaults</tt>: a hash of parameter names and their default
      #   values
      #
      # - <tt>:separators</tt>: where URIs should be split (defaults to
      #   {SEPARATORS})
      #
      # - <tt>:anchor</tt>: whether or not to anchor the URI pattern (defaults
      #   to +false+ for scopes, +true+ for routes)
      #
      # Any additional option specified will be assigned as a constraint if the
      # value is a regular expression, and will be assigned as a default
      # otherwise. Take the following constraint:
      #
      #   get '/users/:id', constraints: { id: /\d+/ } do
      #     # ...
      #   end
      #
      # This can be simplified by merely extracting the constraint to the root
      # of a route's options:
      #
      #   get '/users/:id', id: /\d+/ do
      #     # ...
      #   end
      #
      # You can also route to arbitrary Rack applications:
      #
      #   get RackApp
      #   get '/path', to: RackApp
      #
      # @return [Object#call]
      # @todo
      #   Examples of the other options.
      def route method, path = '/', **options, &block
        app, path = path, '/' if path.respond_to? :call
        app ||= options.delete :to do
          Class.new(config[:endpoint]) { handle block || ->{ head } }
        end

        mount app, options.merge(at: path, method: method, anchor: true)
        app
      end

      # @!method get(*args, &block)
      #   Defines a GET-based route.
      #
      #   @return [void]
      #   @see .route

      # @!method post(*args, &block)
      #   Defines a POST-based route.
      #
      #   @return [void]
      #   @see .route

      # @!method put(*args, &block)
      #   Defines a PUT-based route.
      #
      #   @return [void]
      #   @see .route

      # @!method patch(*args, &block)
      #   Defines a PATCH-based route.
      #
      #   @return [void]
      #   @see .route

      # @!method delete(*args, &block)
      #   Defines a DELETE-based route.
      #
      #   @return [void]
      #   @see .route

      METHODS.each do |method|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{method.downcase} *args, &block # def get *args, &block
            route '#{method}', *args, &block   #   route 'GET', *args, &block
          end                                  # end
        RUBY
      end

      # Defines a route that will match any HTTP verb.
      #
      # @return [void]
      # @see .route
      def any *args, &block
        route nil, *args, &block
      end

      # Specifies configuration for the current scope. All options accepted by
      # {.scope} and {.route} are also valid configuration options.
      #
      # @return [Config]
      # @see .namespace
      # @see .route
      def config **scoped, &block
        return @config if scoped.empty? && block.nil?

        scoped = scoped.merge(
          endpoint: Class.new(scoped.fetch(:endpoint, @config[:endpoint])),
          route_options: normalize_route_options(scoped)
        )
        @config.scope scoped, &block
      end

      # Specifies a scope for routes to inherit options (and base paths) in
      # order to simplify repetitive routing.
      #
      #   get    '/users' # do ... end
      #   post   '/users' # do ... end
      #   get    '/users/:id', id: /\d+/ # do ... end
      #   patch  '/users/:id', id: /\d+/ # do ... end
      #   delete '/users/:id', id: /\d+/ # do ... end
      #
      # Using +namespace+, you only have to specify the "users" component once
      # and the ":id" parameter (and constraint) once:
      #
      #   namespace :users do
      #     get  # { ... }
      #     post # { ... }
      #
      #     namespace ':id', id: /\d+/ do
      #       get    # { ... }
      #       patch  # { ... }
      #       delete # { ... }
      #     end
      #   end
      #
      # Namespaces accept the same options routes accept and pass them to the
      # routes defined within the scope.
      #
      # The {.param} method can simplify the ":id" scope further:
      #
      #   param id: /\d+/ do
      #     # ...
      #   end
      #
      # @return [void]
      # @see .config
      # @see .route
      def namespace path = nil, **options, &block
        config options.merge(namespace: path), &block
      end
      alias scope namespace

      # Specifies a named parameter at the current scope. For example:
      #
      #   param :id do   # scope '/:id' do
      #     # ...        #   # ...
      #   end            # end
      #
      # It accepts all the same options as {.scope}, but allows the named
      # parameter as the first key as a shorthand when a contraint or default
      # is needed:
      #
      #   param id: /\d+/ do
      #     # ...
      #   end
      #
      # @return [void]
      # @see .scope
      def param name = nil, **options, &block
        name ||= options.keys.first
        namespace "/:#{name}", options, &block
      end

      # Specifies a version:
      #
      #   version :v1 do
      #     # ...
      #   end
      #
      # Crepe supports versioning by path prefix, header, or query string.
      # Path-based versioning is the default (so the above behaves much like
      # {.scope}, namespacing its endpoints with a '/v1' path component).
      #
      # To use header-based versioning (versioning by content negotiation),
      # configure versioning before any specific versions are declared:
      #
      #   version with: :header, vendor: 'my-app'
      #
      #   version :v1 do
      #     # ...
      #   end
      #
      # To explicitly match a route in the above scope, set your request's
      # accept header:
      #
      #   Accept: application/vnd.my-app-v1+json
      #
      # In case you want to version with a query parameter:
      #
      #   version with: :query, name: 'v'
      #
      # With header or query parameter versioning, the first version declared
      # will be considered the default, and requests that are not explicitly
      # versioned will be directed to it. Alternatively, you can specify a
      # default version explicitly:
      #
      #   version with: :header, vendor: 'my-app', default: :v1
      #
      # @return [void]
      # @see .scope
      def version level = nil, **options, &block
        config[:version][:default] ||= level
        with = options.fetch :with, config[:version][:with]
        path = level if with == :path
        scope path, version: options.merge(level: level, with: with), &block
      end

      # Extends endpoints with helper methods.
      #
      # It accepts a block:
      #
      #   helper do
      #     let(:user) { User.find params[:id] }
      #     def present resource
      #       UserPresenter.new(resource).present
      #     end
      #   end
      #   get do
      #     present user
      #   end
      #
      # Or a module:
      #
      #   helper AuthenticationHelper
      #
      # @return [void]
      def helper mod = nil, prepend: false, &block
        if block
          warn 'block takes precedence over module' if mod
          config[:endpoint].class_eval(&block)
        else
          config[:endpoint].send prepend ? :prepend : :include, mod
        end
      end

      # Pushes the given Rack middleware and its arguments onto the API's
      # middleware stack.
      #
      # Middleware cannot be nested within a scope. If you need middleware to
      # apply to a specific section of your API, it should be mounted as a
      # sub-API within your stack.
      #
      # @return [void]
      # @raise [ArgumentError] when called inside a scope
      def use middleware, *args, &block
        if config[:namespace]
          raise ArgumentError, "can't nest middleware in a scope"
        end
        config[:middleware] << [middleware, args, block]
      end

      # Rack call interface. Runs each time a request enters the stack.
      #
      # @param [Hash] env the Rack request environment
      # @return [[Integer, Hash, #each]] status code, headers, body
      def call env
        app.call env
      end

      # Mounts a Rack-based application (including other Crepe API subclasses)
      # in an API.
      #
      #   mount MyRackApp
      #
      # Applications can be mounted within a scope:
      #
      #   scope :some_path do
      #     mount MyRackApp
      #   end
      #
      # Or explicitly mapped to a path inline:
      #
      #   mount MyRackApp, at: :some_path
      #
      # Alternatively:
      #
      #   mount MyRackApp => :some_path
      #
      # @return [void]
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

        options = normalize_route_options options

        conditions = {
          path_info: mount_path(path, options), request_method: method
        }
        if level = config[:version][:level]
          case config[:version][:with]
            when :query  then conditions[:query_version]   = /\A#{level}\Z/
            when :header then conditions[:header_versions] = /\A#{level}\Z/
          end
        end

        routes << [app, conditions, options[:defaults], config.dup]
      end

      # Compiles the middleware, routes, and endpoints into a Rack application.
      # (Called the first time {.call} is.)
      #
      #   MyAPI.to_app
      #   # => #<Proc>
      #
      # @param [Array<#call>] exclude middleware to exclude (to prevent
      #   double-mounting in nested APIs)
      # @return [Proc] a compiled app
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

      def inherited subclass
        subclass.config = config.deep_collection_dup
        subclass.config[:endpoint] = Class.new config[:endpoint]
        subclass.routes = routes.dup
      end

      def method_missing name, *args, &block
        return super unless config[:endpoint].respond_to? name
        config[:endpoint].send name, *args, &block
      end

      def respond_to_missing? name, include_private = false
        config[:endpoint].respond_to? name or super
      end

      def app
        @app ||= to_app
      end

      def normalize_route_options options
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

      # Generates OPTIONS and "Method Not Allowed" routes against every path
      # in the route set at compile time, making Crepe APIs easier to
      # inspect.
      def generate_options_routes!
        paths = routes.group_by { |_, cond| cond[:path_info] }
        paths.each do |path, options|
          allowed = options.map { |_, cond| cond[:request_method] }
          next if allowed.include?('OPTIONS') || allowed.none?

          allowed << 'HEAD' if allowed.include? 'GET'
          allowed << 'OPTIONS'
          allowed.sort!

          formats = options.inject([]) do |f, (_, _, _, config)|
            f + config[:endpoint].config[:formats]
          end
          formats.uniq!

          generate_options_route! path, allowed, formats
        end
      end

      # Generates an OPTIONS route and "Method Not Allowed" routes for a
      # given path.
      #
      # @param [String] path a path to generate an OPTIONS route for
      # @param [Array<String>] allowed a list of allowed methods
      # @param [Array<Symbol>] formats a list of formats to respond to
      # @see .generate_options_routes!
      def generate_options_route! path, allowed, formats
        scope do
          respond_to(*formats)
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
        @@catch ||= any('*catch') { error! :not_found } # generate root 404

        routes.map do |app, conditions, defaults, config|
          if app.is_a?(Class) && app < API
            app = configure_api_subclass app, exclude: exclude
          elsif app.is_a?(Class) && app < config[:endpoint]
            app = configure_endpoint_subclass app, config
          end

          [app, conditions, defaults]
        end
      end

      def configure_api_subclass klass, options
        api = Class.new klass
        Crepe.const_set "#{klass.name || 'API'}_#{api.object_id}", api
        api.to_app options
      end

      def configure_endpoint_subclass klass, config
        Class.new(klass).tap do |ep|
          Crepe.const_set "#{klass.name || 'Endpoint'}_#{ep.object_id}", ep
        end
      end

    end

  end
end
