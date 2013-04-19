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
          callbacks: {
            after: [],
            before: [
              Filter::Acceptance
            ]
          },
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
      @format ||= params.fetch(:format, config[:formats].first).to_sym
    end

    def response
      @response ||= Response.new
    end

    def status value = nil
      response.status = Rack::Utils.status_code value if value
      response.status
    end

    delegate :headers, to: :response

    def content_type
      @content_type ||= begin
        extension = format == :json && params[:callback] ? :js : format
        content_type = Rack::Mime.mime_type ".#{extension}"
        "#{content_type}; charset=utf-8"
      end
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

    def expires_in seconds, options = {}
      response.cache_control.update options.merge max_age: seconds
    end

    def expires_now
      response.cache_control.replace no_cache: true
    end

    protected

      def call! env
        @env = env

        payload = catch :halt do
          begin
            parse request.body unless request.body.blank?
            run_callbacks :before
            _run_handler
          rescue => e
            handle_exception e
          end
        end
        render payload if payload && response.body.nil?
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
          code = :internal_server_error
          error! code, exception.message, backtrace: exception.backtrace
        end
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
        { error: data.merge(message: message) }
      end

  end
end
