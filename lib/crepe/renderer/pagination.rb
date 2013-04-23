require 'uri'

module Crepe
  module Renderer
    module Pagination

      # Generates pagination links based on provided page, limit, and total.
      class Links < Struct.new :request, :page, :per_page, :count

        def render
          to_h.map { |rel, uri| %(<#{uri}"}>; rel="#{rel}") }.join ', '
        end

        def first
          return if page == 1
          {} # page=1
        end

        def prev
          return if page == 1
          prev = page.pred
          prev > 1 ? { page: prev } : {} # page=1
        end

        def next
          if count.nil? || page * per_page < count
            { page: page.next } unless page == last[:page]
          end
        end

        def last
          last = (count.to_f / per_page).ceil
          { page: last } unless page == last
        end

        def to_h
          uri = URI request.url
          params = request.GET.except 'page'

          links = { first: first, prev: prev, next: self.next, last: last }
          links.each_key do |rel|
            query = links[rel]
            next links.delete rel unless query
            uri += "?#{params.merge(query).to_query}" unless query.empty?
            links[rel] = uri.to_s
          end
        end

      end

      PER_PAGE = 20

      attr_accessor :links

      def render resource, options = {}
        if resource.respond_to? :paginate
          count = resource.count if resource.respond_to? :count
          endpoint.headers['Count'] = count.to_s if count

          params = endpoint.params.slice :page, :per_page
          page = validate_param params, :page, 1
          per_page = resource.per_page if resource.respond_to? :per_page
          per_page = validate_param params, :per_page, per_page || PER_PAGE
          self.links = Links.new endpoint.request, page, per_page, count
          endpoint.headers['Link'] = links.render

          resource = resource.paginate params
        end

        super if defined? super

        resource
      end

      private

        def validate_param params, name, default
          value = Integer params.fetch(name, default.to_s), 10
          raise ArgumentError if value < 1
          value
        rescue ArgumentError
          endpoint.error!(
            :bad_request, "Invalid value #{params[name]} for #{name}"
          )
        end

    end
  end
end
