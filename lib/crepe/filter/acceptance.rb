module Crepe
  module Filter
    # A default before filter that makes sure an endpoint is capable of
    # responding with a format acceptable to the request.
    class Acceptance

      class << self

        def filter endpoint
          endpoint.instance_eval do
            unless format
              @format = config[:formats].first
              media_types = Util.media_types config[:formats]
              error! :not_acceptable, accepts: media_types
            end
          end
        end

      end

    end
  end
end
