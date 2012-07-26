module Cape
  class Endpoint

    module Acceptance
      class << self

        def filter endpoint
          endpoint.instance_eval do
            unless config[:formats].include? format.to_s
              @format = config[:formats].first
              error! :not_acceptable
            end
          end
        end

      end
    end

  end
end
