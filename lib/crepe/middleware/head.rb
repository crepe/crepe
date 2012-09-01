module Crepe
  module Middleware
    # This middleware wraps boths sides of a request.
    #
    # Going in, it munges the Rack environment so that a HEAD request
    # masquerades as a GET request by the time it hits a Crepe Endpoint. The
    # Crepe request helper will know it's a HEAD request by referring to the
    # `crepe.original_request_method` environment value.
    #
    # Going out, it ensures an empty response body.
    class Head

      def initialize app
        @app = app
      end

      def call env
        if env['REQUEST_METHOD'] == 'HEAD'
          env['crepe.original_request_method'] = 'HEAD'
          env['REQUEST_METHOD'] = 'GET'
          status, headers, _ = @app.call env
          [status, headers, []]
        else
          @app.call env
        end
      end

    end
  end
end
