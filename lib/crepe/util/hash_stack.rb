require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/module/delegation'

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

      delegate :[]=, :delete,
        to: :top

      def key? key
        stack.any? { |frame| frame.key? key }
      end

      def [] key
        found_at = stack.reverse.detect { |frame| frame.key? key }
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
        stack.inject({}, &:merge)
      end
      alias_method :to_h, :to_hash

      def dup
        self.class.new Util.deep_dup stack
      end

      private

        attr_reader :stack

    end
  end
end

