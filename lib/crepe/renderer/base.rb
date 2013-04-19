module Crepe
  module Renderer
    # Basic base class for rendering that stops processing HEAD requests when
    # called in subclasses.
    class Base

      attr_reader :endpoint

      def initialize endpoint
        @endpoint = endpoint
      end

      def render resource, **options
        throw :head if endpoint.request.head?
        resource
      end

    end
  end
end
