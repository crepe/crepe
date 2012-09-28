module Crepe
  class Endpoint
    module Renderer
      class Tilt < Base

        class MissingTemplate < RenderError
        end

        class << self

          def configure
            yield self
          end

          def template_path
            @template_path ||= 'app/views'
          end

          attr_writer :template_path

        end

        def render resource, options = {}
          resource      = super

          format        = options.fetch :format,   endpoint.format
          handlers      = options.fetch :handlers, [:rabl, :erb, :*]
          template_name = options.fetch :template, model_name(resource)

          unless template_name
            return Simple.new(endpoint).render resource, options
          end

          path_options = { format: format, handlers: handlers }
          unless template = find_template(template_name, path_options)
            raise MissingTemplate,
              "Missing template #{template_name} with #{path_options}"
          end

          # FIXME: this is only needed for Rabl, which doesn't support Tilt
          # locals properly. Can probably move into a Renderer::Rabl.
          endpoint.instance_variable_set :"@#{template_name}", resource
          endpoint.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            attr_reader :#{template_name}
          RUBY

          template.render endpoint
        end

        private

          def model_name resource
            if resource.respond_to? :model_name
              resource.model_name.tableize
            elsif resource.class.respond_to? :model_name
              resource.class.model_name.underscore
            end
          end

          def find_template relative_path, path_options
            path_query = File.join self.class.template_path, relative_path

            format, handlers = path_options.values
            path_query << '.{%{format}.{%{handlers}},{%{handlers}}}' % {
              format: format, handlers: handlers.join(',')
            }

            template_path = Dir[path_query].reject { |path|
              ext = File.basename(path).split('.').last
              File.directory?(path) || ::Tilt.mappings[ext].nil?
            }.first

            template_path && ::Tilt.new(template_path)
          end

      end
    end
  end
end
