require 'rack/request'

module Crepe
  # A thin wrapper over {Rack::Request} that provides helper methods to
  # better access request attributes.
  class Request < Rack::Request

    @@env_keys = Hash.new { |h, k| h[k] = "HTTP_#{k.upcase.tr '-', '_'}" }

    def method
      @method ||= env['crepe.original_request_method'] || request_method
    end

    def head?
      method == 'HEAD'
    end

    def path
      @path ||= Util.normalize_path! super
    end

    def headers
      @headers ||= Hash.new { |h, k| h.fetch @@env_keys[k], nil }.update env
    end

    alias query_parameters GET

    def POST
      env['crepe.input'] || super
    end
    alias request_parameters POST

    def path_parameters
      @path_parameters ||= env['rack.routing_args'] || {}
    end

    def parameters
      @parameters ||= path_parameters.merge self.GET.merge self.POST
    end
    alias params parameters

    def body
      env['crepe.input'] || begin
        body = super
        body.respond_to?(:read) ? body.read : body
      end
    end

    def credentials
      @credentials ||= begin
        request = Rack::Auth::Basic::Request.new env
        request.provided? ? request.credentials : []
      end
    end

  end
end
