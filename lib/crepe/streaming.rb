module Crepe
  # Add streaming to your API.
  #
  #   class Ticker < Crepe::API
  #     extend Crepe::Streaming
  #
  #     stream do
  #       loop do
  #         render timestamp: Time.now.to_i
  #         sleep 1
  #       end
  #     end
  #   end
  module Streaming

    # A simple IO-like wrapper to handle chunked streaming responses.
    class ChunkedIO < SimpleDelegator

      def write data
        super "#{data.size.to_s 16}\r\n#{data}\r\n"
      end

      def puts data
        write "#{data.chomp}\n"
      end

      def close
        write ''
        super
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

    # Defines a (GET-based) route with a streaming response.
    #
    # @return [void]
    # @see API.route
    # @see Helper#stream
    def stream *args, &block
      get(*args) { stream { instance_eval(&block) } }
    end

    # Streaming helper method module.
    module Helper

      # Handles the streaming portion of a response given a block.
      #
      # @return [ChunkedIO] the stream itself
      # @see Streaming#stream
      # @see #render
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
                @stream.close
              end
            end
          end
          throw :halt
        end
        @stream if defined? @stream
      end

      # Renders a resource and newline to the stream.
      #
      #   render timestamp: Time.now.to_i
      #
      # If you need more granular control over the stream's output, you can
      # write to the {#stream} directly.
      #
      # @see #stream
      # @see ChunkedIO.puts
      # @see ChunkedIO.write
      def render object, options = {}
        stream ? stream.puts(renderer.render(object, options)) : super
      end

    end

  end
end
