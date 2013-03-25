module Crepe
  module Filter
    class BasicAuth

      def initialize *args, &block
        raise ArgumentError, 'no block given' unless block_given?
        @args, @block = args, block
      end

      def filter endpoint
        unless endpoint.instance_exec endpoint.request.credentials, &@block
          endpoint.unauthorized!(*@args)
        end
      end

    end
  end
end
