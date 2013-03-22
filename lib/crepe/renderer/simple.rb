module Crepe
  module Renderer
    # The simplest renderer delegates rendering to the resource itself.
    class Simple < Paginate

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
