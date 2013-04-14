module Crepe
  module Util
    # A {Hash}-like object that scopes state changes using an underlying stack.
    class HashStack

      def initialize first = {}
        @stack = Array.wrap first
      end

      delegate :pop, :push, :<<,
        to: :stack

      def now
        stack.last
      end

      delegate :[], :[]=, :delete, :merge, :update,
        to: :now

      def all key
        stack.map { |frame| frame[key] }.flatten 1
      end

      def with frame = {}
        self << to_hash.deep_merge(frame)
        yield
        pop
      end

      def to_hash
        stack.inject :deep_merge
      end
      alias to_h to_hash

      def deep_dup
        self.class.new stack.deep_dup
      end

      attr_reader :stack
      private :stack

    end
  end
end

