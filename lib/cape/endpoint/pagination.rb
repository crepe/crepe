module Cape
  class Endpoint

    module Pagination
      class << self

        def filter endpoint
          endpoint.instance_eval do
            if body.respond_to? :paginate
              headers['Count'] = body.count.to_s
              self.body = body.paginate params.slice(:page, :per_page)
            end
          end
        end

      end
    end

  end
end
