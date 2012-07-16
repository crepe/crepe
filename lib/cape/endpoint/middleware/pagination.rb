require 'active_support/core_ext/hash/slice'
require 'cape/params'
require 'rack/request'

module Cape
  class Endpoint

    module Middleware
      class Pagination

        def initialize app
          @app = app
        end

        def call env
          status, headers, body = @app.call env

          resource = body.first
          if resource.respond_to? :paginate
            headers['Count'] = body.count.to_s

            params = Params.new Rack::Request.new(env).params
            resource = resource.paginate params.slice(:page, :per_page)
          end

          [status, headers, [resource]]
        end

      end
    end

  end
end
