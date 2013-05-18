require 'multi_json'

module Crepe
  module Renderer
    # The simplest renderer delegates rendering to the resource itself.
    class Simple < Base

      include Pagination

      def render resource, format: endpoint.format
        resource = super

        if format == :json
          MultiJson.dump resource, pretty: endpoint.params[:pretty]
        elsif resource.respond_to? "to_#{format}"
          resource.__send__ "to_#{format}"
        else
          resource.to_s
        end
      end

    end
  end
end
