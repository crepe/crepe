module Crepe
  module Helper
    # URL helper method module.
    #
    #   class MyAPI < Crepe::API
    #     helper Crepe::Helper::URLFor
    #
    #     get do
    #       { users: url_for(:users) }
    #     end
    #   end
    module URLFor

      # Generates a fully-qualified URL given path components and a parameter
      # hash.
      #
      #   url_for :users, user, :followers, filter: 'following'
      #   # => "http://localhost:9292/users/1/followers?filter=following"
      #
      # @param [Array<#to_param>] components a list of path components
      # @param [Hash] query a hash of query parameters
      # @return [String] a fully-qualified, compiled URL
      #--
      # FIXME: doesn't work with path/query versioning
      #++
      def url_for *components, **query
        url = "#{request.scheme}://#{request.host_with_port}"
        url << Util.normalize_path!(components.map(&:to_param).join('/'))
        extension = query.delete :format do
          format if request.path.split('.').last == format.to_s
        end
        url << ".#{extension}" if extension
        url << "?#{query.to_query}" unless query.empty?
        url
      end

    end
  end
end
