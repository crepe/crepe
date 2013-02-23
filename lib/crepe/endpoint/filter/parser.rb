require 'active_support/core_ext/object/blank'

module Crepe
  class Endpoint
    module Filter
      # A default before filter that parses the body of an incoming request.
      class Parser

        class << self

          def filter endpoint
            endpoint.instance_eval do
              body = request.body
              return if body.blank?

              input = env['crepe.input'] = case request.content_type
              when %r{application/json}
                begin
                  MultiJson.load body
                rescue MultiJson::DecodeError
                  error! :bad_request, "Invalid JSON"
                end
              when %r{application/xml}
                begin
                  MultiXml.parse body
                rescue MultiXml::ParseError
                  error! :bad_request, "Invalid XML"
                end
              else
                error! :unsupported_media_type,
                  %(Content-type "#{request.content_type}" not supported)
              end

              @params = @params.merge input if input.is_a? Hash
            end
          end

        end

      end
    end
  end
end
