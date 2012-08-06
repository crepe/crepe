require 'cape/params'

module Cape
  class Endpoint

    autoload :Request,    'cape/endpoint/request'
    autoload :Pagination, 'cape/endpoint/pagination'
    autoload :Rendering,  'cape/endpoint/rendering'

    attr_reader :config

    attr_reader :env

    attr_accessor :body

    def initialize config = {}, &block
      defaults = {
        after:    [],
        before:   [],
        formats:  %w[json],
        handler:  block,
        helpers:  [],
        rescuers: []
      }

      @config = defaults.update config

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
      @format ||= params.fetch(:format, config[:formats].first).to_sym
    end

    def status *args
      @status = args.first unless args.empty?
      @status || 200
    end

    def headers
      @headers ||= {}
    end

    def error! code, message, data = {}
      status code
      throw :error, error: data.merge(message: message)
    end

    def unauthorized! message = nil, realm = nil
      headers['WWW-Authenticate'] = %(Basic realm="#{realm}")
      error! 401, message || 'Unauthorized'
    end

    protected

      def call! env
        @env = env
        extend *config[:helpers] unless config[:helpers].empty?
        self.body = catch :error do
          begin
            config[:before].each { |filter| run_filter filter }
            instance_eval &config[:handler]
          rescue Exception => e
            handle_exception e
          end
        end
        config[:after].each { |filter| run_filter filter }
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
          instance_exec(exception, &rescuer[:block])
        else
          code = rescuer && rescuer[:options][:status] || 500
          error! code, exception.message, backtrace: exception.backtrace
        end
      end

  end
end
