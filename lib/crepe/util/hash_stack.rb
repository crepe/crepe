module Crepe
  module Util
    # A {Hash}-like object that scopes state changes using an underlying stack.
    class HashStack

      def initialize first = {}
        @stack = Array.wrap first
      end

      delegate :pop, :push, :<<, :last,
        to: :stack

      delegate :[], :[]=, :delete, :slice, :update,
        to: :last

      def all key
        stack.select { |l| l.key? key }.map { |l| l[key] }.flatten 1
      end

      def scope *scoped, **updates
        return update updates unless block_given?
        push updates.merge slice(*scoped).deep_dup
        yield
        pop
      end

      def to_hash
        stack.inject :deep_merge
      end
      alias to_h to_hash

      def + other
        self.class.new stack + other.send(:stack)
      end

      def dup
        self.class.new stack.dup
      end

      def deep_dup
        self.class.new stack.deep_dup
      end

      attr_reader :stack
      private :stack

    end
  end
end

