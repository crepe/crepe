require 'rack/mime'

module Crepe
  class Endpoint
    module Renderer
      class Base

        attr_reader :endpoint

        def initialize endpoint
          @endpoint = endpoint
        end

        def render resource, options = {}
          if instance_of? Base
            raise TypeError, 'render must be called on subclass'
          end

          format = options.fetch :format, endpoint.format
          format = :js if format == :json && endpoint.params[:callback]

          content_type = Rack::Mime.mime_type ".#{format}"
          vendor       = endpoint.config[:vendor]
          version      = endpoint.params[:version]

          if vendor || version
            type, subtype = content_type.split '/'
            content_type  = "#{type}/vnd.#{vendor || 'cape'}"
            content_type << ".#{version}" if version
            content_type << "+#{subtype}"
          end
          endpoint.headers['Content-Type'] = content_type

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
