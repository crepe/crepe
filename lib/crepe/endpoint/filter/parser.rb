module Crepe
  class Endpoint
    module Filter
      class Parser

        class << self

          def filter endpoint
            endpoint.instance_eval do
              # parse things here
            end
          end

        end

      end
    end
  end
end
