require 'rack/utils'
require 'active_support/core_ext/string/inflections'

module Crepe
  module Middleware
    # Middleware to handle JavaScript callbacks.
    class JSCallback

      def initialize app, param = :callback
        @app, @param = app, param.to_s
      end

      def call env
        status, headers, body = @app.call env

        params = Rack::Utils.parse_nested_query env['QUERY_STRING']
        return [status, headers, body] unless function = params[@param]

        body = body.join
        body = body.to_json unless headers['Content-Type'] =~ %r{[/+]json\b}
        body = '%{function}(%{body},%{headers},%{status})' % {
          function: function,
          body:     body,
          headers:  camelize(headers),
          status:   status
        }

        headers['Content-Type'] = 'application/javascript; charset=utf-8'
        [200, headers, [body]]
      end

      private

        def camelize headers
          headers = headers.each_with_object({}) do |(key, value), hash|
            hash[key.to_s.underscore.camelize :lower] = value
          end
          headers.to_json
        end

    end
  end
end
