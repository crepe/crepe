require 'json'
require 'rack/utils'

module Crepe
  # A single {API} endpoint.
  class Endpoint

    # Raised when render is called and a response body is already present.
    class DoubleRenderError < StandardError
    end

    @config = {
      callbacks: { before: [], after: [] },
      formats: [:json],
      renderers: Hash.new(Renderer::Simple),
      parses: [:json],
      parsers: Hash.new(Parser::Simple),
      rescuers: {
        Params::Missing => -> e { error! :bad_request, e.message, e.data },
        Params::Invalid => -> e { error! :bad_request, e.message, e.data }
      }
    }

    class << self

      # @return [Hash] Endpoint configuration
      attr_reader :config, :handler

      # @return [Proc] Handler proc
      delegate :to_proc, to: :handler

      # Rack call interface, delegated to instance.
      #
      # @return [[Numeric, Hash, #each]]
      delegate :call, to: :new

      def respond handler = nil, &block
        @handler = handler || block
        define_method :_run_handler, &@handler
      end

      # Defines supported response formats (mime types) for a scope.
      #
      #   respond_to :json, :xml
      #
      # These formats will override any that are defined in parent scopes.
      #
      # Renderers can be defined at the same time.
      #
      #   respond_to csv: CSVRenderer
      #   # class CSVRenderer < Crepe::Renderer::Base
      #   #   def render resource, options = {}
      #   #     super.to_csv
      #   #   end
      #   # end
      #
      # @return [void]
      # @see .render
      def respond_to *formats, **renderers
        config[:formats] = formats | renderers.keys
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
        formats.each { |f| config[:renderers][f] = renderer }
      end

      # Defines supported request formats (mime types) for a scope.
      #
      # E.g., to parse form data instead of the default, JSON:
      #
      #   parses(*Rack::Request::FORM_DATA_MEDIA_TYPES)
      #
      # These formats will override any that are defined in parent scopes.
      #
      # Parsers can be defined at the same time.
      #
      #   parses csv: CSVParser
      #   # class CSVParser < Struct.new :endpoint
      #   #   def parse body
      #   #     CSV.table body
      #   #   end
      #   # end
      def parses *media_types, **parsers
        config[:parses] = media_types | parsers.keys
        parsers.each { |media_type, parser| parse media_type, with: parser }
      end

      # Defines a custom request body parser for the specified content types.
      #
      #   parse :csv, with: CSVParser.new
      #
      # An endpoint must support the media type for it to be parsed.
      #
      # @return [void]
      # @see .parses
      def parse *media_types, **options
        parser = options.fetch :with
        Util.media_types(media_types).each { |t| config[:parsers][t] = parser }
      end

      # Rescues exceptions raised in endpoints.
      #
      #   rescue_from ActiveRecord::RecordNotFound do |e|
      #     error! :not_found, e.message
      #   end
      #
      # Helper methods can be used (instead of blocks).
      #
      #   rescue_from ActiveRecord::RecordNotFound, with: :not_found
      #   helper do
      #     def not_found e
      #       error! :not_found, e.message
      #     end
      #   end
      #
      # @return [void]
      # @raise [ArgumentError] if a block/method handler isn't set
      # @see .helper
      # @see #error!
      def rescue_from *exceptions, with: nil, &block
        warn 'block takes precedence over handler' if block && with
        handler = block || with
        raise ArgumentError, 'block or handler required' unless handler
        exceptions.each { |e| config[:rescuers][e] = handler }
      end

      # Defines a DSL method for creating callbacks.
      #
      # Used, for example, to define {.before} and {.after}.
      #
      # @param [Symbol] type the name of the DSL method
      # @return [void]
      # @see .before
      # @see .after
      def define_callback type
        config[:callbacks][type] ||= []

        instance_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{type} filter = nil, &block
            warn 'block takes precedence over object' if block && filter
            callback = block || filter
            raise ArgumentError, 'block or filter required' unless callback
            config[:callbacks][:#{type}] << callback
          end

          def skip_#{type} filter = nil, &block
            warn 'block takes precedence over object' if block && filter
            callback = block || -> c { filter == c || filter === c }
            raise ArgumentError, 'block or filter required' unless callback
            config[:callbacks][:#{type}].delete_if(&callback)
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
      # @see #unauthorized!
      def basic_auth *args, &block
        skip_before Filter::BasicAuth
        before Filter::BasicAuth.new(*args, &block)
      end

      # Defines a memoized helper method.
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
          raise ArgumentError, "can't redefine #{self}##{name}"
        end
        define_method "_eval_#{name}", &block
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{name} *args
            return @_memo_#{name}[args] if (@_memo_#{name} ||= {}).key? args
            @_memo_#{name}[args] = _eval_#{name}(*args)
          end
        RUBY
      end

      # Defines a memoized helper method that is invoked before an endpoint is
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
        before name.to_sym
      end

      protected

      attr_writer :config

      private

      def inherited subclass
        subclass.config = Util.deep_collection_dup config
      end

    end

    # @return [Hash] The Rack env
    attr_reader :env

    # @return [Hash]
    # @see .config
    delegate :config, to: :class

    # Convenience method accesses the Logger currently assigned to
    # {Crepe.logger}.
    #
    #   get do
    #     logger.info "..."
    #     # ...
    #   end
    #
    # @return [Logger]
    # @see Crepe.logger
    delegate :logger, to: :Crepe

    # Runs a given block _before_ a request runs through a route's handler.
    #
    #   before do
    #     @current_user = User.authenticate!(*request.credentials)
    #   end
    #
    # Alternatively, calls an object's #filter method, passing the {Endpoint}
    # instance as an argument.
    #
    #   before UserAuthenticator.new
    #   # class UserAuthenticator
    #   #   def filter endpoint
    #   #     User.authenticate!(*endpoint.request.credentials)
    #   #   end
    #   # end
    #
    # @method (filter = nil, &block)
    # @scope class
    # @return [void]
    # @raise [ArgumentError] if a block/filter isn't set
    # @see .let!
    # @see .basic_auth
    define_callback :before

    # Runs a given block _after_ a request runs through a route's handler.
    #
    #   after do
    #     Jobs.schedule AnalyticsJob, request
    #   end
    #
    # Alternatively, calls an object's #filter method, passing the {Endpoint}
    # instance as an argument.
    #
    #   after JobScheduler.new
    #   # class JobScheduler.new
    #   #   def filter endpoint
    #   #     Jobs.schedule AnalyticsJob, endpoint.request
    #   #   end
    #   # end
    #
    # @method (filter = nil, &block)
    # @scope class
    # @return [void]
    # @raise [ArgumentError] if a block/filter isn't set
    define_callback :after

    # An object representing the current request.
    #
    # @return [Request]
    def request
      @request ||= Request.new env
    end

    # A {Params} object wrapping +request.params+.
    #
    # @return [Params]
    def params
      @params ||= Params.new request.params
    end

    # The most acceptable format requested, e.g. +:json+.
    #
    # @return [Symbol]
    def format
      return @format if defined? @format
      formats = Util.media_types config[:formats]
      media_type = Rack::Utils.best_q_match accepts, formats
      @format = config[:formats].find { |f| Util.media_type(f) == media_type }
    end

    # An object representing the current response.
    #
    # @return [Response]
    def response
      @response ||= Response.new
    end

    # Sets the status code.
    #
    # Accepts a symbol:
    #
    #   status :ok
    #
    # Or numeric value:
    #
    #   status 200
    #
    # Without an argument, it will return the current status code as an
    # integer.
    #
    # @return [Integer] status code
    def status value = nil
      if value
        response.status = env['crepe.status'] = Rack::Utils.status_code value
      end

      response.status
    end

    delegate :headers, to: :response

    # @return [String] the response's content (media) type
    def content_type
      @content_type ||= "#{Util.media_type format}; charset=utf-8"
    end

    # Parses the request body and, if possible, merges the results with
    # {#params}.
    #
    # @note Called automatically before an endpoint executes.
    # @return [void]
    # @see .parse
    def parse body, options = {}
      unless Util.media_types(config[:parses]).include? request.media_type
        error! :unsupported_media_type,
          %(Content-Type "#{request.media_type}" not supported)
      end
      request.body = parser.parse body
      @params = params.merge request.body if request.body.is_a? Hash
    end

    # Renders the response body.
    #
    # @note Called automatically with an endpoint's return value.
    # @return [String] the rendered response body
    # @raise [DoubleRenderError] if the response body has already rendered
    # @see .render
    # @see .respond_to
    def render object, options = {}
      headers['Content-Type'] ||= content_type
      raise DoubleRenderError, 'body already rendered' if response.body
      response.body = catch(:head) { renderer.render object, options }
    end

    # Throws a response with an empty body. Like {#status}, it accepts a symbol
    # or numeric value to set the response's HTTP status.
    #
    #   head :accepted
    #
    # It also accepts a hash of HTTP headers.
    #
    #   head :found, location: 'https://www.example.org/'
    #
    # @return [void]
    def head code = nil, **options
      status code if code
      options.each do |key, value|
        headers[key.to_s.tr('_', '-').gsub(/\b[a-z]/) { $&.upcase }] = value
      end
      throw :halt
    end

    # Throws a response with a redirect location and status.
    #
    #   redirect_to updated_url, status: :moved_permanently
    #
    # @return [void]
    # @see #head
    def redirect_to location, status: :see_other
      head status, location: location
    end

    # Throws a formatted error response.
    #
    #   error! :not_found, 'Not found', _links: [
    #     support: { href: '/support' }
    #   ]
    #
    # @return [void]
    # @see .rescue_from
    def error! code = :bad_request, message = nil, **data
      throw :halt, error(code, message, data)
    end

    # Throws a formatted 401 Unauthorized error response.
    #
    #   unauthorized! 'Unauthorized', realm: 'My App'
    #
    # @return [void]
    # @see #error!
    # @see .basic_auth
    def unauthorized! message = 'Unauthorized', realm: 'API', **data
      headers['WWW-Authenticate'] = %(Basic realm="#{realm}")
      error! :unauthorized, message, data
    end

    # Throws a formatted 406 Not Acceptable error response.
    #
    # @note Called automatically in the request-response life cycle if no
    #   accepted format can be rendered.
    # @return [void]
    # @see #error!
    def not_acceptable! message = nil, **data
      @format ||= config[:formats].first
      media_types = Util.media_types config[:formats]
      error! :not_acceptable, message, data.merge(accepts: media_types)
    end

    # Sets a Cache-Control response header. Private by default to prevent
    # intermediate caching.
    #
    #   expires_in 20.minutes
    #   expires_in 3.hours, public: true, must_revalidate: true
    #
    # @return [void]
    def expires_in seconds, options = {}
      response.cache_control.update options.merge max_age: seconds
    end

    # Sets a Cache-Control response header of "no-cache" to advise clients (and
    # proxies) against caching.
    #
    # @return [void]
    def expires_now
      response.cache_control.replace no_cache: true
    end

    # Rack call logic.
    #
    # @param [Hash] env the Rack request environment
    # @return [[Integer, Hash, #each]]
    def call env
      @env = env

      halt = catch :halt do
        begin
          not_acceptable! unless format
          parse request.body if request.body.present?
          run_callbacks :before
          payload = _run_handler
          render payload if payload && response.body.nil?
          nil
        rescue => e
          handle_exception e
        end
      end
      render halt if halt
      run_callbacks :after

      response.finish
    end

    private

    def run_callbacks type
      config[:callbacks][type].each do |c|
        c.respond_to?(:filter) ? c.filter(self) : instance_eval(&c)
      end
    end

    def handle_exception exception
      classes = config[:rescuers].keys.select { |c| exception.is_a? c }

      if handler = config[:rescuers][classes.sort.first]
        handler = method handler if handler.is_a? Symbol
        instance_exec(*(exception unless handler.arity.zero?), &handler)
      else
        log_exception exception
        code = :internal_server_error
        data = { backtrace: exception.backtrace } if Crepe.env.development?
        error! code, exception.message, data || {}
      end
    end

    def log_exception exception
      logger.error "%{message}\n%{backtrace}" % {
        message: exception.message,
        backtrace: exception.backtrace.map { |l| "\t#{l}" }.join("\n")
      }
    end

    def parser
      config[:parsers][request.content_type].new self
    end

    def renderer
      config[:renderers][format].new self
    end

    def error code, message = nil, **data
      status code
      message ||= Rack::Utils::HTTP_STATUS_CODES[status]
      { error: { message: message }.merge(data) }
    end

    def accepts
      Util.media_type(params[:format]) || request.headers['Accept'] || '*/*'
    end

  end
end
