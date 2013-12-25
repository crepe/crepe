require 'multi_json'

module Crepe
  module Parser
    # A base parser class that attempts to parse common MIME types.
    class Simple

      attr_reader :endpoint

      def initialize endpoint
        @endpoint = endpoint
      end

      delegate :error!, :request, to: :endpoint

      def parse body
        case request.media_type
        when %r{application/x-www-form-urlencoded}, %r{multipart/form-data}
          request.POST
        when %r{application/json}
          begin
            MultiJson.load body
          rescue MultiJson::DecodeError
            error! :bad_request, "Invalid JSON"
          end
        else
          error! :unsupported_media_type,
            %(Content-Type "#{request.media_type}" not supported)
        end
      end

    end
  end
end
