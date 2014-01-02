require 'json'
require 'rack/utils'

module Crepe
  # A single {API} endpoint.
  class Endpoint

    # Raised when render is called and a response body is already present.
    class DoubleRenderError < StandardError
    end

    class << self

      def default_config
        @default_config ||= {
          callbacks: [
            [:before, :ensure_acceptable]
          ],
          formats: [:json],
          parsers: Hash.new(Parser::Simple),
          renderers: Hash.new(Renderer::Simple),
          rescuers: {
            Params::Missing => -> e { error! :bad_request, e.message, e.data },
            Params::Invalid => -> e { error! :bad_request, e.message, e.data }
          }
        }
      end

    end

    # @return [Hash] Endpoint configuration
    attr_reader :config

    # @return [Hash] The Rack env
    attr_reader :env

    alias dup clone

    def initialize config = {}, &handler
      configure! config
      define_singleton_method :_run_handler, &handler
    end

    # @return [Logger]
    # @see Crepe.logger
    delegate :logger, to: :Crepe

    def configure! new_config
      @config ||= self.class.default_config
      @config = Util.deep_merge config, new_config

      @handle_request_chain = Callbacks::Chain.new(
        :handle_request, config[:callbacks]
      )
    end

    # Rack call interface.
    #
    # @return [[Numeric, Hash, #each]]
    def call env
      clone.call! env
    end

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
      media_type = request.accepts.best_of Util.media_types config[:formats]
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
    # Without an argument, it will return the current status code.
    #
    # @return [Numeric]
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
    # @see API.parse
    def parse body
      request.body = parser.parse body
      @params = params.merge request.body if request.body.is_a? Hash
    end

    # Renders the response body.
    #
    # @note Called automatically with an endpoint's return value.
    # @return [String] the rendered response body
    # @raise [DoubleRenderError] if the response body has already rendered
    # @see API.render
    # @see API.respond_to
    def render object, options = {}
      headers['Content-Type'] ||= content_type
      raise DoubleRenderError, 'body already rendered' if response.body
      response.body = catch(:head) { renderer.render object, options }
    end

    # Throws a response with an empty body.
    #
    #   head :accepted
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
    # @see API.rescue_from
    def error! code = :bad_request, message = nil, **data
      throw :halt, error(code, message, data)
    end

    # Throws a formatted 401 Unauthorized error response.
    #
    #   unauthorized! 'Unauthorized', realm: 'My App'
    #
    # @return [void]
    # @see #error!
    # @see API.basic_auth
    def unauthorized! message = nil, **data
      realm = data.delete(:realm) { config[:vendor] }
      headers['WWW-Authenticate'] = %(Basic realm="#{realm}")
      error! :unauthorized, message || data.delete(:message), data
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

    protected

      def call! env
        @env = env

        halt = catch :halt do
          begin
            handle_request_chain.call self
            nil
          rescue => e
            handle_exception e
          end
        end
        render halt if halt

        response.finish
      end

      attr_reader :handle_request_chain

    private

      def ensure_acceptable
        not_acceptable! unless format
      end

      def handle_request
        parse request.body if request.body.present?
        payload = _run_handler
        render payload if payload && response.body.nil?
        payload
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

  end
end
