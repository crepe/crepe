module Crepe
  module Middleware
    class Format

      def initialize app
        @app = app
      end

      def call env
        status, headers, body = @app.call env
        [status, headers, [body.to_json]]
      end

      # RablHelper = Class.new.extend ::Rabl::Helpers

      # def after
      #   return super if request.request_method == 'HEAD'

      #   status, headers, bodies = *@app_response

      #   endpoint = env['api.endpoint']
      #   template = endpoint.options[:route_options][:rabl]

      #   if template != false and resource = bodies.first
      #     resource = resource.to_ary if resource.respond_to? :to_ary
      #     resource_name = RablHelper.data_name(resource)

      #     template = case template
      #     when String, Symbol
      #       template.to_s
      #     else
      #       resource_name.pluralize
      #     end

      #     # create tilt engine from template path
      #     engine = Tilt.new template_path(template)

      #     # update endpoint context with instance var
      #     endpoint.instance_variable_set(:"@#{resource_name}", resource)

      #     # render view using endpoint as context
      #     bodies = [engine.render(endpoint, {})]
      #   end

      #   [status, headers, bodies.map(&:to_s)]
      # end

      # private

      # def template_path path
      #   unless view_path = ::Rabl.configuration.view_paths.first
      #     raise 'Use Rabl.configuration to set #view_paths'
      #   end
      #   path += '.rabl' unless path.split('.').last == 'rabl'
      #   File.join view_path, path
      # end

    end
  end
end
