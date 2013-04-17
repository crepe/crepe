module Crepe
  module Helper
    module URLFor

      #--
      # FIXME: doesn't work with path/query versioning
      #++
      def url_for *args, **options
        url = "#{request.scheme}://#{request.host_with_port}"
        args.each { |c| url << "/#{c.to_param}" }
        extension = options.delete(:format) { format }
        url << ".#{extension}" if extension
        url << "?#{options.to_query}" unless options.empty?
        url
      end

    end
  end
end
