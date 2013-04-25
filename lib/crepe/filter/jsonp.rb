module Crepe
  module Filter
    # An after-callback to handle JSON-to-JSONP conversions.
    class JSONP

      def initialize param = :callback
        @param = param
      end

      def filter endpoint
        param = @param
        endpoint.instance_eval do
          if format == :json && params[param]
            status :ok
            headers['Content-Type'] = 'application/javascript; charset=utf-8'
            response.body = "#{params[param]}(#{response.body});"
          end
        end
      end

    end
  end
end
