require 'rack/request'

module Crepe
  class Endpoint
    class Request < Rack::Request

      @@env_keys = Hash.new { |h, k| h[k] = "HTTP_#{k.upcase.tr '-', '_'}" }

      def headers
        @headers ||= Hash.new { |h, k| h.fetch @@env_keys[k], nil }.update env
      end

      def method
        @method ||= env['crepe.original_request_method'] || request_method
      end

      def head?
        method == 'HEAD'
      end

      alias query_parameters GET

      alias request_parameters POST

      def path_parameters
        @path_parameters ||= env['rack.routing_args'] || {}
      end

      def parameters
        @parameters ||= path_parameters.merge self.GET.merge(self.POST)
      end
      alias params parameters

      def credentials
        @credentials ||= begin
          request = Rack::Auth::Basic::Request.new env
          request.provided? ? request.credentials : []
        end
      end

    end
  end
end
