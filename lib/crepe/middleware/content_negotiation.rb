require 'rack/utils'

module Crepe
  module Middleware
    # Negotiates API content type and version from an Accept header.
    #
    # Given an Accept header with a vendor-specific mime type, it will
    # transform the Rack environment: prefixing a version and postfixing
    # an extension to the path, and removing the vendor-specific parts of the
    # Accept header.
    #
    # E.g., the following request:
    #
    #   GET /users
    #   Accept: application/vnd.crepe-v2+json
    #
    # Will pass through to the next middleware as this:
    #
    #   GET /v2/users.json
    #   Accept: application/json
    #
    # The vendor name is stored as <tt>crepe.vendor</tt> in the Rack
    # environment.
    #
    #   env['crepe.vendor'] # => "crepe"
    #--
    # TODO: Support Accept headers with multiple mime types:
    #
    #   Accept: application/vnd.crepe-v2+xml, application/vnd.crepe-v1+xml;q=0.7
    #
    # XXX: Should the env be modified more? Should we store version
    # somewhere? As is, this middleware depends heavily on Crepe and
    # Rack::Mount to be useful.
    #++
    class ContentNegotiation

      # Matches an `type`, `vendor`, `version`, and `format` (subtype) given
      # an accept header.
      ACCEPT_HEADER = %r{
        (?<type>[^/;,\s]+)
          /
        (?:
          (?:
            (?:vnd\.)(?<vendor>[^/;,\s\.+-]+)
            (?:-(?<version>[^/;,\s\.+-]+))?
            (?:\+(?<format>[^/;,\s\.+-]+))?
          )
        |
          (?<format>[^/;,\s\.+]+)
        )
      }ix

      MIME_TYPES = {
        'application/json' => :json,
        'application/pdf'  => :pdf,
        'application/xml'  => :xml,
        'text/html'        => :html,
        'text/plain'       => :txt
      }

      def initialize app
        @app = app
      end

      def call env
        accept = ACCEPT_HEADER.match(env['HTTP_ACCEPT']) || {}
        path = env['crepe.original_path_info'] = env['PATH_INFO']

        env['crepe.vendor'] = accept[:vendor]

        version = accept_version(accept, env) || query_string_version(env)
        if version && !path.start_with?("/#{version}")
          path = ::File.join '/', version, path
        end

        if accept[:format]
          env['crepe.original_http_accept'] = env['HTTP_ACCEPT'].dup
          content_type = [accept[:type], accept[:format]].join '/'

          env['HTTP_ACCEPT'][ACCEPT_HEADER] = content_type
          extension = MIME_TYPES.fetch content_type, accept[:format]

          if ::File.extname(path) != ".#{extension}"
            path += ".#{extension}" unless extension == '*'
          end
        end

        env['PATH_INFO'] = Util.normalize_path path

        @app.call env
      end

      private

        def accept_version accept, env
          if accept[:version]
            env['crepe.content_negotiation'] = :header
          end
          accept[:version]
        end

        def query_string_version env
          env['crepe.original_query_string'] = env['QUERY_STRING']
          query = Rack::Utils.parse_nested_query env['QUERY_STRING']

          version = query.delete('v')
          if version
            env['crepe.content_negotiation'] = :query
            env['QUERY_STRING'] = query.to_query
            version
          end
        end

    end
  end
end
