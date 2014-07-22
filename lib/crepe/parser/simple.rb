require 'json'
require 'rack/request'

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
        when *Rack::Request::FORM_DATA_MEDIA_TYPES
          request.POST
        when 'application/json'
          begin
            JSON.parse body
          rescue JSON::ParserError
            error! :bad_request, "Invalid JSON"
          end
        else
          body
        end
      end

    end
  end
end
