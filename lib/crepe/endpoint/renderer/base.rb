
module Crepe
  class Endpoint
    module Renderer
      # A base renderer class that sets pagination headers.
      class Base

        attr_reader :endpoint

        def initialize endpoint
          @endpoint = endpoint
        end

        def render resource, options = {}
          if instance_of? Base
            raise TypeError, 'render must be called on subclass'
          end

          if resource.respond_to? :paginate
            endpoint.headers['Count'] = resource.count.to_s
            params = endpoint.params.slice :page, :per_page
            resource = resource.paginate params
          end

          throw :head if endpoint.request.head?

          resource
        end

      end
    end
  end
end
