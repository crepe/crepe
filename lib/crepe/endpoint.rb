require 'json'
require 'rack/utils'

module Crepe
  # A single API endpoint.
  class Endpoint

    autoload :Filter,   'crepe/endpoint/filter'
    autoload :Renderer, 'crepe/endpoint/renderer'
    autoload :Request,  'crepe/endpoint/request'

    class << self

      def default_config
        {
          after_filters: [],
          before_filters: [
            Filter::Acceptance,
            Filter::Parser
          ],
          formats: [:json],
          handler: nil,
          renderers: Hash.new(Renderer::Tilt),
          rescuers: []
        }
      end

    end

    attr_reader :config

    attr_reader :env

    attr_accessor :body

    def initialize config = {}, &block
      @config = self.class.default_config.deep_merge config
      @status = 200

      if block
        warn 'block takes precedence over handler option' if @config[:handler]
        @config[:handler] = block
      end

      if @config[:formats].empty?
        raise ArgumentError, 'wrong number of formats (at least 1)'
      end

      @config.freeze
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

    def status value = nil
      @status = Rack::Utils.status_code value if value
      @status
    end

    def headers
      @headers ||= {}
    end

    def content_type
      @content_type ||= begin
        extension = format == :json && params[:callback] ? :js : format
        content_type = Rack::Mime.mime_type ".#{extension}"
        vendor = config[:vendor]
        version = params[:version]

        if vendor || version
          type, subtype = content_type.split '/'
          content_type  = "#{type}/vnd.#{vendor || 'crepe'}"
          content_type << ".#{version}" if version
          content_type << "+#{subtype}"
        end

        content_type
      end
    end

    def render object, options = {}
      renderer = config[:renderers][format].new self
      if stream
        stream.puts renderer.render object, options
      else
        headers['Content-Type'] ||= content_type
        self.body ||= catch(:head) { renderer.render object, options }
      end
    end

    def head code = nil, options = {}
      options, code = code if code.is_a? Hash
      status code if code
      options.each do |key, value|
        headers[key.to_s.tr('_', '-').gsub(/\b[a-z]/) { $&.upcase }] = value
      end
      throw :halt
    end

    def redirect_to location, options = {}
      head options.fetch :status, :see_other, location: location
    end

    def stream
      if block_given?
        headers['rack.hijack'] = -> io do
          begin
            @stream = io
            yield
          ensure
            io.close
          end
        end
        throw :halt, [status, headers, nil]
      else
        @stream if instance_variable_defined? :@stream
      end
    end

    def error! code = :bad_request, message = nil, data = {}
      throw :halt, error(code, message, data)
    end

    def unauthorized! message = nil, data = {}
      data, message = message, nil if message.respond_to? :each_pair
      realm = data.delete(:realm) { config[:vendor] }
      headers['WWW-Authenticate'] = %(Basic realm="#{realm}")
      error! :unauthorized, message || data.delete(:message), data
    end

    def fresh_when object, options = {}
      options, object = object if object.is_a? Hash

      etag options.fetch :etag, object unless etag
      last_modified options.fetch(:last_modified) {
        object.updated_at if object.respond_to? :updated_at
      } unless last_modified
      headers['Cache-Control'] = 'public' if options[:public]

      if request.last_modified && last_modified
        modified = last_modified > request.last_modified
      end
      if request.etag
        modified = etag != request.etag
      end

      head :not_modified unless modified

      object
    end

    def etag object = nil
      return headers['ETag'] unless object
      headers['ETag'] ||= Digest::MD5.hexdigest(
        ActiveSupport::Cache.expand_cache_key object
      )
    end

    def last_modified at = nil
      return headers['Last-Modified'] unless at
      headers['Last-Modified'] = at
    end

    protected

      def call! env
        @env = env

        halt = catch :halt do
          begin
            config[:before_filters].each { |filter| run_filter filter }
            render fresh_when instance_eval(&config[:handler])
            break
          rescue => e
            handle_exception e
          end
        end
        render halt if halt
        config[:after_filters].each { |filter| run_filter filter }

        [status, headers, [*body]]
      end

    private

      def run_filter filter
        return filter.filter self if filter.respond_to? :filter
        filter = filter.to_proc if filter.respond_to? :to_proc
        instance_eval(&filter)
      end

      def handle_exception exception
        rescuer = config[:rescuers].find do |r|
          exception.is_a? r[:exception_class]
        end

        if rescuer && rescuer[:block]
          instance_exec exception, &rescuer[:block]
        else
          code = rescuer && rescuer[:options].fetch(:status, :bad_request) ||
            :internal_server_error
          error! code, exception.message, backtrace: exception.backtrace
        end
      end

      def error code, message = nil, data = {}
        data, message = message, nil if message.respond_to? :each_pair
        status code
        message ||= Rack::Utils::HTTP_STATUS_CODES[status]
        { error: data.merge(message: message) }
      end

  end
end
