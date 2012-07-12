module Cape
  module Middleware
    class Head

      def initialize app
        @app = app
      end

      def call env
        if env['REQUEST_METHOD'] == 'HEAD'
          env['cape.original_request_method'] = 'HEAD'
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
