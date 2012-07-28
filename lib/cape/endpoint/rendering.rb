require 'rack/mime'
require 'active_support/all' # For #to_json.

module Cape
  class Endpoint

    module Rendering
      class << self

        def filter endpoint
          endpoint.instance_eval do
            headers['Content-Type'] = Rack::Mime.mime_type ".#{format}"

            if request.head?
              self.body = nil
              return
            end

            if body.respond_to? :model_name
              resource_name = body.model_name.tableize
            elsif body.class.respond_to? :model_name
              resource_name = body.class.model_name.underscore
            end

            if resource_name
              # FIXME: Raise if Rabl.configuration.view_paths.nil?
              template_path = File.join(
                Rabl.configuration.view_paths.first, "#{resource_name}.rabl"
              )
              self.body = Tilt.new(template_path).render self
            else
              self.body = body.to_json if body
            end
          end
        end

      end
    end

  end
end
