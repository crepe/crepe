require 'cape/params'

module Cape
  class Endpoint

    autoload :Filter,   'cape/endpoint/filter'
    autoload :Renderer, 'cape/endpoint/renderer'
    autoload :Request,  'cape/endpoint/request'

    class << self

      def default_config
        {
          after_filters: [],
          before_filters: [
            Filter::Acceptance,
            Filter::Parser
          ],
          formats: %w[json],
          handler: nil,
          helpers: [],
          renderer: Renderer::Tilt,
          rescuers: []
        }
      end

    end

    attr_reader :config

    attr_reader :handler

    attr_reader :env

    attr_accessor :body

    def initialize config = {}, &block
      @config = self.class.default_config.update config
      @handler = @config[:handler] || block || ->{}
      @status = 200

      if @config[:formats].empty?
        raise ArgumentError, 'wrong number of formats (at least 1)'
      end
    end

    def call env
      dup.call! env
    end

    def request
      @request ||= Request.new env
    end

    def params
      @params ||= Params.new request.params
    end

    def format
      @format ||= params[:format].to_sym
    end

    def status value = nil
      @status = Rack::Utils.status_code value if value
      @status
    end

    def headers
      @headers ||= {}
    end

    def render object, options = {}
      self.body ||= catch :head do
        config[:renderer].new(self).render object, options
      end
    end

    def error! code, message = nil, data = {}
      throw :error, error(code, message, data)
    end

    def unauthorized! message = nil, data = {}
      data, message = message if message.is_a? Hash
      headers['WWW-Authenticate'] = %(Basic realm="#{data.delete :realm}")
      error! :unauthorized, message || data.delete(:message), data
    end

    protected

      def call! env
        @env = env
        extend *config[:helpers] unless config[:helpers].empty?

        error = catch :error do
          begin
            config[:before_filters].each { |filter| run_filter filter }
            render instance_eval(&handler)
            break
          rescue => e
            handle_exception e
          end
        end
        render error if error
        config[:after_filters].each { |filter| run_filter filter }

        [status, headers, [body]]
      end

    private

      def run_filter filter
        return filter.filter self if filter.respond_to? :filter
        filter = filter.to_proc if filter.respond_to? :to_proc
        instance_eval &filter
      end

      def handle_exception exception
        rescuer = config[:rescuers].find do |r|
          exception_class = eval("::#{r[:class_name]}") rescue nil
          exception_class && exception.kind_of?(exception_class)
        end

        if rescuer && rescuer[:block]
          instance_exec exception, &rescuer[:block]
        else
          code = rescuer && rescuer[:options][:status] ||
            :internal_server_error
          error! code, exception.message, backtrace: exception.backtrace
        end
      end

      def error code, message = nil, data = {}
        status code
        message ||= Rack::Utils::HTTP_STATUS_CODES[status]
        { error: data.merge(message: message) }
      end

  end
end
