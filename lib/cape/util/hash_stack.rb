require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/module/delegation'

module Cape
  module Util
    class HashStack

      def initialize first = {}
        @stack = Array.wrap first
      end

      def top
        stack.last
      end

      delegate :[]=, :merge!, :delete, to: :top

      def merge hash
        dup.merge! hash
      end

      def key? key
        stack.any? { |frame| frame.key? key }
      end

      def [] key
        found_at = stack.reverse.detect { |frame| frame.key? key }
        found_at && found_at[key]
      end

      def push hash = {}
        stack << hash
        self
      end
      alias_method :<<, :push

      delegate :pop, to: :stack

      def all key
        stack.collect { |frame| frame[key] }.flatten 1
      end

      def with frame = {}
        self << frame
        yield
        pop
      end

      def to_hash
        stack.inject({}) { |hash, frame| hash.merge frame }
      end

      def dup
        self.class.new Util.deep_dup stack
      end

      private

        attr_reader :stack

    end
  end
end

