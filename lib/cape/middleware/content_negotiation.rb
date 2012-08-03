module Cape
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
    #   Accept: application/vnd.cape.v2+json
    #
    # Will pass through to the next middleware as this:
    #
    #   GET /v2/users.json
    #   Accept: application/json
    #
    # The vendor name is stored as <tt>cape.vendor</tt> in the Rack
    # environment.
    #
    #   env['cape.vendor'] # => "cape"
    #--
    # TODO: Support Accept headers with multiple mime types:
    #
    #   Accept: application/vnd.cape.v2+xml, application/vnd.cape.v1+xml;q=0.7
    #
    # XXX: Should the env be modified more? Should we store version
    # somewhere? As is, this middleware depends heavily on Cape and
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
            (?:vnd\.)?
            (?<vendor>[^/;,\s\.+]+)\.
            (?<version>[^/;,\s\.+]+)
            (?:\+)?
          )?
          (?<format>[^/;,\s\.+]+)
        )
      }ix

      MIME_TYPES = {
        'application/json' => :json,
        'application/pdf'  => :pdf,
        'application/xml'  => :xml,
        'text/html'        => :html,
        'text/plain'       => :text
      }

      def initialize app
        @app = app
      end

      def call env
        if accept = ACCEPT_HEADER.match(env['HTTP_ACCEPT'])
          path = env['cape.original_path_info'] = env['PATH_INFO']

          if accept[:vendor]
            env['cape.vendor'] = accept[:vendor]
          end

          if accept[:version]
            path = ::File.join '/', accept[:version], path
          end

          if accept[:format]
            env['HTTP_ACCEPT'] = [accept[:type], accept[:format]].join '/'

            if ::File.extname(path).empty?
              if extension = MIME_TYPES[env['HTTP_ACCEPT']]
                path += ".#{extension}"
              end
            end
          end

          env['PATH_INFO'] = path
        end

        @app.call env
      end

    end
  end
end
