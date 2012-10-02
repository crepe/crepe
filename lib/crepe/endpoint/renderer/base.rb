require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/object/to_query'
require 'rational'
require 'uri'

module Crepe
  class Endpoint
    module Renderer
      # A base renderer class that sets pagination headers.
      class Base

        # Generates pagination links based on provided page, limit, and total.
        class Links < Struct.new :page, :per_page, :count

          def render request
            uri = URI request.url
            params = request.query_parameters.except 'page'

            links = {
              first: first, prev: prev, next: self.next, last: last
            }
            links = links.map do |rel, query|
              next unless query
              %(<#{uri + "?#{params.merge(query).to_query}"}>; rel="#{rel}")
            end

            links.compact.join ', '
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
            last = Rational(count, per_page).ceil
            { page: last } unless page == last
          end

        end

        PER_PAGE = 20

        attr_reader :endpoint

        def initialize endpoint
          @endpoint = endpoint
        end

        def render resource, options = {}
          if resource.respond_to? :paginate
            count = resource.count if resource.respond_to? :count
            endpoint.headers['Count'] = count.to_s if count

            params = endpoint.params.slice :page, :per_page
            page = validate_param params, :page, 1
            per_page = resource.per_page if resource.respond_to? :per_page
            per_page = validate_param params, :per_page, per_page || PER_PAGE
            links = Links.new page, per_page, count
            endpoint.headers['Link'] = links.render endpoint.request

            resource = resource.paginate params
          end

          throw :head if endpoint.request.head?

          resource
        end

        private

          def validate_param params, name, default
            value = Integer params.fetch(name, default.to_s), 10
            raise ArgumentError if value < 1
            value
          rescue ArgumentError
            endpoint.error! 400, "Invalid value #{params[name]} for #{name}"
          end

      end
    end
  end
end
