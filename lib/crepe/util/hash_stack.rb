module Crepe
  module Util
    # A {Hash}-like object that scopes state changes using an underlying stack.
    class HashStack

      def initialize first = {}
        @stack = Array.wrap first
      end

      delegate :pop, :push, :<<,
        to: :stack

      def top
        stack.last
      end

      delegate :[]=, :update, :delete,
        to: :top

      delegate :keys,
        to: :to_h

      def key? key
        stack.any? { |frame| frame.key? key }
      end

      def [] key
        found_at = stack.reverse.find { |frame| frame.key? key }
        found_at && found_at[key]
      end

      def all key
        stack.map { |frame| frame[key] }.flatten 1
      end

      def with frame = {}
        self << frame
        yield
        pop
      end

      def to_hash
        stack.inject :merge
      end
      alias to_h to_hash

      def dup
        self.class.new Util.deep_dup stack
      end

      attr_reader :stack
      private :stack

    end
  end
end

