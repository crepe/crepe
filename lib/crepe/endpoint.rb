require 'json'
require 'rack/utils'

module Crepe
  # A single API endpoint.
  class Endpoint

    # Raised when render is called and a response body is already present.
    class DoubleRenderError < StandardError
    end

    class << self

      def default_config
        @default_config ||= {
          callbacks: {},
          formats: [:json],
          parsers: Hash.new(Parser::Simple),
          renderers: Hash.new(Renderer::Tilt),
          rescuers: {}
        }
      end

    end

    attr_reader :config

    attr_reader :env

    alias dup clone

    def initialize config = {}, &handler
      configure! config
      define_singleton_method :_run_handler, &handler
    end

    delegate :logger, to: :Crepe

    def configure! new_config
      @config ||= self.class.default_config
      @config = Util.deep_merge config, new_config
      if config[:formats].empty?
        raise ArgumentError, 'wrong number of formats (at least 1)'
      end
    end

    def call env
      clone.call! env
    end

    def request
      @request ||= Request.new env
    end

    def params
      @params ||= Params.new request.params
    end

    def format
      return @format if defined? @format
      media_type = request.accepts.best_of Util.media_types config[:formats]
      @format = config[:formats].find { |f| Util.media_type(f) == media_type }
    end

    def response
      @response ||= Response.new
    end

    def status value = nil
      if value
        response.status = env['crepe.status'] = Rack::Utils.status_code value
      end

      response.status
    end

    delegate :headers, to: :response

    def content_type
      @content_type ||= "#{Util.media_type format}; charset=utf-8"
    end

    def parse body, options = {}
      request.body = parser.parse body
      @params = params.merge request.body if request.body.is_a? Hash
    end

    def render object, options = {}
      headers['Content-Type'] ||= content_type
      raise DoubleRenderError, 'body already rendered' if response.body
      response.body = catch(:head) { renderer.render object, options }
    end

    def head code = nil, **options
      status code if code
      options.each do |key, value|
        headers[key.to_s.tr('_', '-').gsub(/\b[a-z]/) { $&.upcase }] = value
      end
      throw :halt
    end

    def redirect_to location, status: :see_other
      head status, location: location
    end

    def error! code = :bad_request, message = nil, **data
      throw :halt, error(code, message, data)
    end

    def unauthorized! message = nil, **data
      realm = data.delete(:realm) { config[:vendor] }
      headers['WWW-Authenticate'] = %(Basic realm="#{realm}")
      error! :unauthorized, message || data.delete(:message), data
    end

    def not_acceptable! message = nil, **data
      @format ||= config[:formats].first
      media_types = Util.media_types config[:formats]
      error! :not_acceptable, message, data.merge(accepts: media_types)
    end

    def expires_in seconds, options = {}
      response.cache_control.update options.merge max_age: seconds
    end

    def expires_now
      response.cache_control.replace no_cache: true
    end

    protected

      def call! env
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

  end
end
