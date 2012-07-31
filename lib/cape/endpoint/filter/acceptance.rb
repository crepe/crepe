module Cape
  class Endpoint
    module Filter
      class Acceptance

        class << self

          def filter endpoint
            endpoint.instance_eval do
              unless config[:formats].include? format.to_s
                @format = config[:formats].first
                not_acceptable = true
              end

              error! :not_acceptable if not_acceptable
            end
          end

        end

      end
    end
  end
end
