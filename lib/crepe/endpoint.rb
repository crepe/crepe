require 'oj'
require 'ox'

module Crepe
  class Endpoint
    autoload :Middleware, 'crepe/endpoint/middleware'

    attr_reader :settings

    attr_reader :env

    def initialize settings
      @settings = settings
      (@settings[:middleware] ||= []).concat [
        Middleware::Format,
        Middleware::Pagination
      ]
    end

    def call env
      if endpoint = env['crepe.endpoint']
        body = catch :error, &endpoint.method(:eval_handler)
        [endpoint.status, endpoint.headers, [body]]
      else
        app.call env.merge!('crepe.endpoint' => instance(env))
      end
    end

    def logger
      @logger ||= Logger.new STDOUT
    end

    def headers
      @headers ||= { 'Content-Type' => content_type }
    end

    def params
      @params ||= Params.new query_params.merge(body_params)
    end

    def request
      @request ||= Rack::Request.new env
    end

    def error! code, message, data = {}
      status code
      throw :error, :error => data.merge(:message => message)
    end

    def format
      query_params.fetch(:format, settings[:formats].first).to_sym
    end

    def content_type
      mime = Rack::Mime.mime_type ".#{format}"
      env.fetch 'CONTENT_TYPE', mime
    end

    def status *args
      @status = args.first unless args.empty?
      @status || 200
    end

    def credentials
      @credentials ||= begin
        request = Rack::Auth::Basic::Request.new env
        request.provided? ? request.credentials : []
      end
    end

    protected

      attr_writer :env

    private

      def app
        @app ||= begin
          builder = Rack::Builder.new
          settings[:middleware].each { |middleware| builder.use *middleware }
          builder.run self
          builder.to_app
        end
      end

      def instance env
        dup.extend(*settings[:helpers]).tap { |instance| instance.env = env }
      end

      def query_params
        request.params.merge env["rack.routing_args"] || {}
      end

      def body_params
        method = request.request_method.downcase.to_sym
        return {} unless [:post, :put, :patch].include? method
        return {} unless request.body.length > 0

        case content_type
        when 'application/json'
          Oj.load response.body.read
        when 'application/xml'
          Ox.parse response.body.read
        else
          {}
        end
      end

      def eval_handler *_
        instance_eval &settings[:handler]
      rescue Exception => e
        handle_exception e
      end

      def handle_exception exception
        rescuer = settings[:rescuers].find do |r|
          exception_class = eval("::#{r[:class_name]}") rescue nil
          exception_class && exception.kind_of?(exception_class)
        end

        if rescuer && rescuer[:block]
          instance_exec(exception, &rescuer[:block])
        else
          code = rescuer && rescuer[:options][:status] || 500
          error! code, exception.message, :backtrace => exception.backtrace
        end
      end

  end
end
