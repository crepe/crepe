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

      # @return [Config] API configuration
      attr_reader :config

      # @return [Array] uncompiled routes
      attr_reader :routes

      # The base DSL method of a Crepe API, +route+ defines an API route by
      # method(s), path, options, and a block that is evaluated at runtime.
      #
      #     route 'GET', '/' do
      #       { message: 'Hello, world!' }
      #     end
      #     # renders {"message":"Hello, world!"}
      #
      # Common HTTP verbs (GET, POST, PUT, PATCH, DELETE) are aliased to their
      # own methods, and the path defaults to a forward slash, so the above can
      # be simplified:
      #
      #     get do
      #       { message: 'Hello, world!' }
      #     end
      #
      # Crepe routing should be familiar to anyone who has used Rails or
      # Sinatra. Named path parameters are prefixed with +:+, and are
      # accessible via the +params+ hash.
      #
      #     get '/hello/:name' do
      #       { message: "Hello, #{params[:name]}" }
      #     end
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
      #   get '/users/:id', constraints: { id: /^\d+/ } do
      #     # ...
      #   end
      #
      # This can be simplified by merely extracting the constraint to the root
      # of a route's options:
      #
      #   get '/users/:id', id: /^\d+/ do
      #     # ...
      #   end
      #
      # @return [void]
      # @todo
      #   Examples of the other options.
      def route method, path = '/', **options, &block
        block ||= proc { head }
        endpoint = Endpoint.new(&block)
        mount endpoint, options.merge(at: path, method: method, anchor: true)
      end

      # Defines a GET-based route.
      #
      # @return [void]
      # @see .route
      def get *args, &block
        route 'GET', *args, &block
      end

      # Defines a POST-based route.
      #
      # @return [void]
      # @see .route
      def post *args, &block
        route 'POST', *args, &block
      end

      # Defines a PUT-based route.
      #
      # @return [void]
      # @see .route
      def put *args, &block
        route 'PUT', *args, &block
      end

      # Defines a PATCH-based route.
      #
      # @return [void]
      # @see .route
      def patch *args, &block
        route 'PATCH', *args, &block
      end

      # Defines a DELETE-based route.
      #
      # @return [void]
      # @see .route
      def delete *args, &block
        route 'DELETE', *args, &block
      end

      # Defines a route that will match any HTTP verb.
      #
      # @return [void]
      # @see .route
      def any *args, &block
        route nil, *args, &block
      end

      # Specifies a scope for routes to inherit options (and base paths) in
      # order to simplify repetitive routing.
      #
      #   get    '/users' # do ... end
      #   post   '/users' # do ... end
      #   get    '/users/:id', id: /^\d+$/ # do ... end
      #   patch  '/users/:id', id: /^\d+$/ # do ... end
      #   delete '/users/:id', id: /^\d+$/ # do ... end
      #
      # Using +scope+, you only have to specify the "users" component once and
      # the ":id" parameter (and constraint) once:
      #
      #   scope :users do
      #     get  # { ... }
      #     post # { ... }
      #
      #     scope ':id', id: /^\d+$/ do
      #       get    # { ... }
      #       patch  # { ... }
      #       delete # { ... }
      #     end
      #   end
      #
      # Scopes accept the same options routes accept and pass them to the
      # routes defined within the scope.
      #
      # The {.param} method can simplify the ":id" scope further:
      #
      #   param id: /^\d+$/ do
      #     # ...
      #   end
      #
      # @return [void]
      # @todo
      #   Example of an options-based scope (one without a base path).
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
      #   param id: /^\d+$/ do
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
      # In case you want to version with a query parameter:
      #
      #   version with: :query, name: 'v'
      #
      # @return [void]
      # @see .scope
      def version level = nil, **options, &block
        config[:version][:default] ||= level
        with = options.fetch :with, config[:version][:with]
        path = level if with == :path
        scope path, version: options.merge(level: level, with: with), &block
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

      # Defines supported formats (mime types) for a scope.
      #
      #   respond_to :json, :xml
      #
      # These formats will override any that are defined in parent scopes.
      #
      # Renderers can be defined at the same time:
      #
      #   respond_to csv: CSVRenderer.new
      #   # class CSVRenderer < Crepe::Renderer::Base
      #   #   def render resource, options = {}
      #   #     super.to_csv
      #   #   end
      #   # end
      #
      # @return [void]
      # @see .render
      def respond_to *formats, **renderers
        config[:endpoint][:formats] = formats | renderers.keys
        renderers.each { |format, renderer| render format, with: renderer }
      end

      # Defines a custom renderer for the specified formats (mime types).
      #
      #   render :json, with: MyCustomRenderer.new
      #
      # An endpoint must respond to the specified format for it to render.
      #
      # @return [void]
      # @see .respond_to
      def render *formats, **options
        renderer = options.fetch :with
        formats.each { |f| config[:endpoint][:renderers][f] = renderer }
      end

      # Defines a custom request body parser for the specified content types.
      #
      #   parse :csv, with: CSVParser.new
      #   # class CSVParser < Struct.new :endpoint
      #   #   def parse body
      #   #     CSV.parse body
      #   #   end
      #   # end
      #
      # @return [void]
      def parse *media_types, **options
        parser = options.fetch :with
        media_types = Util.media_types media_types
        media_types.each { |t| config[:endpoint][:parsers][t] = parser }
      end

      # Rescues exceptions raised in endpoints.
      #
      #   rescue_from Crepe::Params::Missing do |e|
      #     error! :bad_request, e.message, missing: e.key
      #   end
      #
      # Helper methods can be used (instead of blocks).
      #
      #   rescue_from Crepe::Params::Invalid, with: :params_invalid
      #   helper do
      #     def params_invalid e
      #       error! :unprocessable_entity, e.message, invalid: e.keys
      #     end
      #   end
      #
      # @return [void]
      # @raise [ArgumentError] if a block/method handler isn't set
      # @see .helper
      # @see Endpoint#error!
      def rescue_from *exceptions, with: nil, &block
        warn 'block takes precedence over handler' if block && with
        handler = block || with
        raise ArgumentError, 'block or handler required' unless handler
        exceptions.each { |e| config[:endpoint][:rescuers][e] = handler }
      end

      # @return [void]
      # @see .before
      # @see .around
      # @see .after
      def define_callback type
        config[:endpoint][:callbacks] ||= []

        instance_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{type} filter = nil, **options, &block
            warn 'block takes precedence over object' if block && filter
            callback = block || filter
            raise ArgumentError, 'block or filter required' unless callback
            config[:endpoint][:callbacks] << [:#{type}, callback, options]
          end

          def skip_#{type} filter = nil, &block
            warn 'block takes precedence over object' if block && filter
            callback = block || proc { |(t, c, _)|
              t == :#{type} && (filter == c || filter === c)
            }
            raise ArgumentError, 'block or filter required' unless callback
            config[:endpoint][:callbacks].delete_if(&callback)
          end
        RUBY
      end

      # Configures a before filter for basic authorization.
      #
      #   basic_auth realm: 'My App' do |username, password|
      #     return username == 'admin' && password == 'secret'
      #   end
      #
      # Renders a 401 Unauthorized error if the block fails.
      #
      # @return [void]
      # @see .before
      # @see Endpoint#unauthorized!
      def basic_auth *args, &block
        skip_before Filter::BasicAuth
        before Filter::BasicAuth.new(*args, &block)
      end

      # Extends endpoints with helper methods.
      #
      # It accepts a block:
      #
      #   helper do
      #     def present resource
      #       UserPresenter.new(resource).present
      #     end
      #   end
      #   get do
      #     user = User.find params[:id]
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
          mod = Module.new(&block)
        end
        method = prepend ? :prepend : :include
        config[:helper].send method, mod
      end

      # Define a memoized helper method.
      #
      #   let(:user) { User.find params[:id] }
      #   get { user }
      #
      # {.let} is not evaluated till the first time the method it defines is
      # invoked. To force a method's invocation before the endpoint runs, use
      # {.let!}.
      #
      # @return [void]
      # @see .let!
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

      # Define a memoized helper method that is invoked before an endpoint is
      # called.
      #
      #   let! :current_user do
      #     User.authenticate!(*request.credentials)
      #   end
      #
      # @return [void]
      # @see .let
      def let! name, &block
        let name, &block
        before { send name }
      end

      # Rack call interface.
      #
      # @return [[Numeric, Hash, #each]]
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
      # @return [Rack::Builder]
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
          subclass.config = config.deep_dup
          subclass.config[:helper] = config[:helper].dup
          subclass.routes = routes.dup
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

        def generate_options_routes!
          paths = routes.group_by { |_, cond| cond[:path_info] }
          paths.each do |path, options|
            allowed = options.map { |_, cond| cond[:request_method] }
            next if allowed.include?('OPTIONS') || allowed.none?

            allowed << 'HEAD' if allowed.include? 'GET'
            allowed << 'OPTIONS'
            allowed.sort!

            formats = options.inject([]) do |f, (_, _, _, config)|
              f + config[:endpoint][:formats]
            end
            formats.uniq!

            generate_options_route! path, allowed, formats
          end
        end

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
            if app.is_a?(Class) && app.ancestors.include?(API)
              app = Class.new(app).to_app exclude: exclude
            elsif app.is_a? Endpoint
              app = app.dup
              app.configure! config.to_h[:endpoint]
              config.all(:helper).each { |helper| app.extend helper }
            end

            [app, conditions, defaults]
          end
        end

    end

    # Runs a given block or calls #filter on a given object (passing the
    # {Endpoint} instance) _before_ a request runs through a route's handler.
    #
    # @method (filter = nil, **options, &block)
    # @scope class
    # @return [void]
    # @raise [ArgumentError] if a block/filter isn't set
    define_callback :before

    # Runs a given block or calls #filter on a given object (passing the
    # {Endpoint} instance and a block) _around_ a request running through a
    # route's handler. The handler is passed as a block to the filter.
    #
    # @method (filter = nil, **options, &block)
    # @scope class
    # @return [void]
    # @raise [ArgumentError] if a block/filter isn't set
    define_callback :around

    # Runs a given block or calls #filter on a given object (passing the
    # {Endpoint} instance) _after_ a request runs through a route's handler.
    #
    # @method (filter = nil, **options, &block)
    # @scope class
    # @return [void]
    # @raise [ArgumentError] if a block/filter isn't set
    define_callback :after

  end
end
