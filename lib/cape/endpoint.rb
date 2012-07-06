require 'oj'
require 'ox'

module Cape
  class Endpoint

    attr_reader :settings

    attr_reader :env

    def initialize settings
      @settings = settings
    end

    def call env
      reset!
      @env = env
      @env['cape.endpoint'] = self
      body = catch(:error) { render }
      [status, headers.merge('Content-Type' => content_type), body]
    end

    def logger
      @logger ||= Logger.new STDOUT
    end

    def headers
      @headers ||= {}
    end

    def params
      @params ||= Params.new query_params.merge(body_params)
    end

    def request
      @request ||= Rack::Request.new env
    end

    def error code, message, data = {}
      status code
      throw :error, data.merge(:message => message)
    end

    def format
      query_params.fetch :format, settings[:default_format]
    end

    def content_type
      mime = Rack::Mime.mime_type ".#{format}"
      headers.fetch 'Content-Type', mime
    end

    def status *args
      @status = args.first unless args.empty?
      @status || 200
    end

    private

    def reset!
      @params  = nil
      @request = nil
      @headers = nil
    end

    def method
      request.request_method.downcase.to_sym
    end

    def query_params
      request.params.merge(env["rack.routing_args"] || {})
    end

    def body_params
      return {} unless [:post, :put, :patch].include? method

      case content_type
      when 'application/json'
        Oj.load response.body.read # FIXME: 500 on empty "" body.
      when 'application/xml'
        Ox.parse response.body.read
      else
        {}
      end
    end

    def render
      instance_eval(&settings[:handler])
    rescue Exception => ex
      handle_exception ex
    end

    def handle_exception error
      rescuer = settings[:rescuers].find do |r|
        error_class = eval("::#{r[:class_name]}") rescue nil
        error_class && error.kind_of?(error_class)
      end

      if rescuer && rescuer[:block]
        instance_exec(error, &rescuer[:block])
      else
        code = rescuer && rescuer[:options][:status] || 500
        error code, error.message, :backtrace => error.backtrace
      end
    end

  end
end
