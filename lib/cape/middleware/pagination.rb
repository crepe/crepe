require 'active_support/core_ext/hash/slice'
require 'cape/params'
require 'rack/request'

module Cape
  module Middleware
    class Pagination

      def initialize app
        @app = app
      end

      def call env
        status, headers, body = @app.call env

        if body.respond_to? :paginate
          headers['Count'] = body.count.to_s

          params = Params.new Rack::Request.new(env).params
          body = body.paginate params.slice(:page, :per_page)
        end

        [status, headers, body]
      end

    end
  end
end
