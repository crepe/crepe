require 'json'

module Crepe
  module Renderer
    # The simplest renderer delegates rendering to the resource itself.
    class Simple < Base

      def render resource, format: endpoint.format
        resource = super

        if format == :json
          render_json resource
        elsif resource.respond_to? "to_#{format}"
          resource.__send__ "to_#{format}"
        else
          resource.to_s
        end
      end

      def render_json resource
        resource = resource.as_json if resource.respond_to? :as_json
        if endpoint.request.GET.key? 'pretty'
          JSON.pretty_generate resource
        else
          JSON.dump resource
        end
      end

    end
  end
end
