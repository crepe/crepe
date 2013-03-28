module Crepe
  module Helper
    module URLFor

      def url_for *args, **options
        url = "#{request.scheme}://#{request.host_with_port}"
        if version
          options[:v] = version if env['crepe.content_negotiation'] == :query
          url << "/#{version}" if env['crepe.content_negotiation'].nil?
        end
        args.each { |c| url << "/#{c.to_param}" }
        extension = options.delete :format do
          if File.extname(env['crepe.original_path_info']) == ".#{format}"
            format
          end
        end
        url << ".#{extension}" if extension
        url << "?#{options.to_query}" unless options.empty?
        url
      end

    end
  end
end
