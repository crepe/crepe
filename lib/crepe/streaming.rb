module Crepe
  module Streaming

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
          headers['rack.hijack'] = -> io do
            begin
              @stream = io
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
