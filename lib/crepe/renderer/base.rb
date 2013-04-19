module Crepe
  module Renderer
    # Basic base class for rendering that stops processing HEAD requests when
    # called in subclasses.
    class Base < Struct.new :endpoint

      def render resource, options = {}
        throw :head if endpoint.request.head?
        resource
      end

    end
  end
end
