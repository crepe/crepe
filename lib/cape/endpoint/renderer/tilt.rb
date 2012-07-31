module Cape
  class Endpoint
    module Renderer
      class Tilt < Base

        class MissingTemplate < StandardError
        end

        class << self

          attr_writer :template_path

          def template_path
            @template_path ||= 'app/views'
          end

          def configure
            yield self
          end

        end

        def render resource, options = {}
          resource      = super

          format        = options.fetch :format,   endpoint.format
          handlers      = options.fetch :handlers, [:rabl, :erb]
          template_name = options.fetch :template, model_name(resource)

          unless template_name
            return Simple.new(endpoint).render resource, options
          end

          # FIXME: I think this is part of the problem where we can render an
          # ERb HTML template for a JSON request and it will still return
          # Content-Type: 'application/json' instead of 'text/html'...
          path_options = { formats: [format, :'*'], handlers: handlers }
          unless template = find_template(template_name, path_options)
            raise MissingTemplate,
              "Missing template #{template_name} with #{path_options}"
          end

          template.render endpoint, template_name => resource
        end

        private

          def model_name resource
            if resource.respond_to? :model_name
              resource.model_name.tableize
            elsif resource.class.respond_to? :model_name
              resource.class.model_name.underscore
            end
          end

          def find_template original_template_path, path_options
            search_path = File.expand_path self.class.template_path
            path_query = File.join search_path, original_template_path

            path_options.values.map(&:presence).compact.each do |ext|
              path_query << '{' + ext.map {|e| ".#{e}" if e }.join(',') + ',}'
            end

            template_path = Dir[path_query].reject { |path|
              ext = File.basename(path).split(".").last
              File.directory?(path) || ::Tilt.mappings[ext].nil?
            }.first

            template_path && ::Tilt.new(template_path)
          end

          def model_name object
            if object.respond_to? :model_name
              object.model_name.tableize
            elsif object.class.respond_to? :model_name
              object.class.model_name.underscore
            end
          end

      end
    end
  end
end
