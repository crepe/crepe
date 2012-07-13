module Crepe
  module Middleware
    class Format

      Helper = Module.new.extend Rabl::Helpers

      def initialize app
        @app = app
      end

      def call env
        return @app.call env if env['crepe.original_request_method'] == 'HEAD'

        status, headers, resource = @app.call env

        resource = resource.to_ary if resource.respond_to? :to_ary
        resource_name = Helper.data_name resource

        engine = Tilt.new template_path(resource_name.pluralize)

        context = env['crepe.endpoint']
        context.instance_variable_set "@#{resource_name}", resource
        body = engine.render context

        [status, headers, [body]]
      end

      private

      def template_path path
        unless view_path = Rabl.configuration.view_paths.first
          raise 'Use Rabl.configuration to set #view_paths'
        end
        path += '.rabl' unless File.extname(path) == '.rabl'
        File.join view_path, path
      end

    end
  end
end
