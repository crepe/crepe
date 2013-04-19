require 'tilt'

module Crepe
  module Renderer
    # Sends a resource and template to [Tilt][] for rendering, falling back
    # to {Renderer::Simple} if no template name is provided (or can be
    # derived). Template names are derived by the resource class's ability to
    # return a {.model_name}.
    #
    # [Tilt]: https://github.com/rtomayko/tilt
    class Tilt < Base

      # Raised when a template name is derived but cannot be found in the
      # template path.
      class MissingTemplate < RenderError
      end

      include Pagination

      class << self

        def configure
          yield self
        end

        def template_path
          @template_path ||= 'app/views'
        end

        def layout_path
          @layout_path ||= template_path
        end

        attr_writer :template_path, :layout_path

      end

      def render resource, options = {}
        resource      = super

        formats       = options.fetch :formats,  [endpoint.format]
        handlers      = options.fetch :handlers, [:*]
        path_options  = { formats: formats, handlers: handlers }

        template_name = options.fetch :template, model_name(resource)
        unless template_name
          return Simple.new(endpoint).render resource, options
        end

        unless template = find_template(template_name, path_options)
          raise MissingTemplate,
            "Missing template #{template_name} with #{path_options}"
        end

        if layout_name = options[:layout]
          layout = find_template layout_name, path_options.merge(layout: true)
          layout.render { template.render endpoint }
        else
          template.render endpoint
        end
      end

      private

        def model_name resource
          if resource.respond_to? :model_name
            resource.model_name.collection
          elsif resource.class.respond_to? :model_name
            resource.class.model_name.singular
          end
        end

        def find_template relative_path, path_options
          path_query = if path_options.delete(:layout)
            File.join self.class.layout_path, relative_path
          else
            File.join self.class.template_path, relative_path
          end

          formats, handlers = path_options.values
          path_query << '{.{%{formats}},}.{%{handlers}}' % {
            formats: formats.join(','), handlers: handlers.join(',')
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
