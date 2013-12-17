module Crepe
  module Middleware
    # This middleware provides intelligent defaults for response status codes
    # depending on the HTTP verb:
    #
    # - POST will provide 201 Created.
    #
    # - DELETE will provide 204 No Content (and clear the response body).
    class RestfulStatus

      def initialize app
        @app = app
      end

      def call env
        status, headers, body = @app.call env

        if status == 200 && !env['crepe.status']
          case env['REQUEST_METHOD']
          when 'POST'
            status = body.empty? ? 204 : 201
          when 'PUT', 'PATCH', 'DELETE'
            status = 204 if body.empty?
          end
        end

        [status, headers, body]
      end
    end

  end
end
