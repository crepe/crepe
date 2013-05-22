module Crepe
  module Filter
    # An after filter to handle JavaScript callbacks.
    class JSCallback

      attr_reader :param

      def initialize param = :callback
        @param = param
      end

      def filter endpoint
        filter = self
        endpoint.instance_eval do
          return unless function = params[filter.param]
          response.body = response.body.to_json unless format == :json
          response.body = '%{function}(%{body},%{headers},%{status});' % {
            function: function,
            body: response.body,
            headers: filter.object_for(headers),
            status: status
          }
          headers['Content-Type'] = 'application/javascript; charset=utf-8'
          status :ok
        end
      end

      def object_for headers
        headers = headers.each_with_object({}) do |(key, value), hash|
          hash[key.to_s.underscore.camelize :lower] = value
        end
        headers.to_json
      end

    end
  end
end
