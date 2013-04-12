module Crepe
  module Streaming

    # Simple wrapper to handle chunked streaming responses.
    class ChunkedIO < SimpleDelegator

      def write data
        super "#{data.size.to_s 16}\r\n#{data}\r\n"
      end

      def puts data
        write "#{data.chomp}\n"
      end

    end

    class << self

      def extended api
        api.class_eval do
          define_callback :before_stream
          define_callback :after_stream

          helper Streaming::Helper, prepend: true
        end
      end

    end

    def stream *args, &block
      get(*args) { stream { instance_eval(&block) } }
    end

    module Helper

      def stream
        if block_given?
          headers['Content-Type'] ||= content_type
          headers['Transfer-Encoding'] = 'chunked'
          headers['rack.hijack'] = -> io do
            begin
              @stream = ChunkedIO.new io
              run_callbacks :before_stream
              yield
            ensure
              begin
                run_callbacks :after_stream
              ensure
                io.close
              end
            end
          end
          throw :halt
        end
        @stream if defined? @stream
      end

      def render object, options = {}
        stream ? stream.puts(renderer.render(object, options)) : super
      end

    end

  end
end
