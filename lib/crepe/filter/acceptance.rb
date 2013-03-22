module Crepe
  module Filter
    # A default before filter that makes sure an endpoint is capable of
    # responding with a format acceptable to the request.
    class Acceptance

      class << self

        def filter endpoint
          endpoint.instance_eval do
            unless config[:formats].include? format
              @format = config[:formats].first
              not_acceptable = true
            end

            if [config[:vendor], env['crepe.vendor']].compact.uniq.length > 1
              not_acceptable = true
            end

            if not_acceptable
              error! :not_acceptable, accepts: config[:formats].map { |f|
                content_type.sub(/#{format}$/, f.to_s)
              }
            end
          end
        end

      end

    end
  end
end
