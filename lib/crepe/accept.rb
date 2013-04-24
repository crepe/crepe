module Crepe
  # Helps negotiate content from an accept header.
  class Accept

    HEADER = %r{
      (?<type>[^/;,\s]+)
        /
      (?<subtype>
        (?:
          (?:
            (?:vnd\.)(?<vendor>[^/;,\s\.+-]+)
            (?:-(?<version>[^/;,\s\.+-]+))?
          )
        |
          [^/;,\s+]+
        )
        (?:\+(?<format>[^/;,\s]+))?
      )
      \s*
      (?:;\s*q=(?<qvalue>\d(?:\.\d+)?))?
    }ix

    def initialize header
      header.scan(HEADER) { |values| media_types << MediaType.new(*values) }
      media_types.sort!
    end

    def media_types
      @media_types ||= []
    end

    def best_of types
      media_types.find do |m|
        type = types.find { |t| Rack::Mime.match? t, m.to_s }
        return type if type
      end
    end

    # Represents a media type's attributes.
    class MediaType

      include Comparable

      attr_reader :type, :subtype, :vendor, :version

      def initialize *values
        @type, @subtype, @vendor, @version, @format, @qvalue = values
      end

      def format
        @format || subtype
      end

      def qvalue
        @qvalue ? @qvalue.to_f : 1
      end

      def <=> other
        other.qvalue <=> qvalue
      end

      def to_s
        "#{type}/#{format}"
      end

    end

  end
end
