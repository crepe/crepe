module Crepe
  module Middleware
    class RestfulStatus

      def initialize app
        @app = app
      end

      def call env
        status, headers, body = @app.call env

        if status == 200
          case env['REQUEST_METHOD']
          when 'POST'
            status = 201
          when 'DELETE'
            status = 204
            body = []
          end
        end

        [status, headers, body]
      end
    end

  end
end
