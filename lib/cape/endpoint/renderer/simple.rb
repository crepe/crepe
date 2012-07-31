module Cape
  class Endpoint
    module Renderer
      class Simple < Base

        def render resource, options = {}
          resource = super
          format = options.fetch :format, endpoint.format

          if resource.respond_to? "to_#{format}"
            resource.__send__("to_#{format}")
          else
            resource.to_s
          end
        end

      end
    end
  end
end
