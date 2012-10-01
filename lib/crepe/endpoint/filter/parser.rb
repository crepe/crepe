module Crepe
  class Endpoint
    module Filter
      # A default before filter that parses the body of an incoming request.
      class Parser

        class << self

          def filter endpoint
            endpoint.instance_eval do
              # TODO: Parse things here.
            end
          end

        end

      end
    end
  end
end
