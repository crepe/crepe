require 'thread'

module Crepe
  # A simple callback system similar to ActiveSupport::Callbacks.
  # Handles 'before', 'around' and 'after' callbacks.
  module Callbacks

    # A callback chain that compiles the given callbacks into a chain around
    # the method name given.
    class Chain

      attr_reader :name, :callbacks, :block

      def initialize name, callbacks = [], &block
        @name, @callbacks, @block, @mutex = name, callbacks, block, Mutex.new
      end

      # Calls the callbacks before, around and after calling the method 'name'
      # on the given target.
      #
      # return [void]
      delegate :call, to: :compiled

      private

      def compiled
        @compiled || @mutex.synchronize do
          @compiled ||= normalized.inject(final) do |chain, callback|
            callback.apply chain
          end
        end
      end

      def final
        block, name = @block, @name
        ->(target) { block ? block.call : target.send(name) }
      end

      def normalized
        chain = @callbacks.map do |cb|
          cb.is_a?(Callback) ? cb : Callback.new(@name, *cb)
        end

        before, after = *chain.partition { |cb| cb.kind != :after }
        before.reverse + after
      end

    end

    # A wrapper around a filter such as a symbol or proc that allows it to be
    # chained with other callbacks and called against the intended target.
    class Callback

      attr_reader :name, :kind, :filter

      def initialize name, kind = :before, filter = name, options = {}
        @name, @kind, @filter, @options = name, kind, filter, options
      end

      def apply chain
        callback = to_proc
        cond = conditions_procs
        cond = false if cond.empty?

        case kind
        when :before
          ->(target) {
            callback.call target if !cond || cond.all? { |c| c.call target }
            chain.call target
          }
        when :around
          ->(target) {
            if cond && !cond.all? { |c| c.call target }
              next chain.call target
            end
            callback.call(target) { chain.call target }
          }
        when :after
          ->(target) {
            chain.call target
            callback.call target if !cond || cond.all? { |c| c.call target }
          }
        end
      end

      def conditions_procs
        if_procs = Array(@options[:if]).map { |filter| make_proc filter }

        unless_procs = Array(@options[:unless]).map do |filter|
          uninverted = make_proc filter
          ->(*args, &blk) { !uninverted.call(*args, &blk) }
        end

        if_procs + unless_procs
      end

      def make_proc filter
        filter = eval "-> { #{filter} }" if filter.is_a?(String)
        case
        when filter.is_a?(Symbol)
          ->(target, &blk) { target.send filter, &blk }
        when filter.is_a?(Proc)
          if filter.arity.zero?
            ->(target, &blk) { target.instance_exec(&filter) }
          else
            ->(target, &blk) { target.instance_exec blk, &filter }
          end
        when filter.respond_to?(:filter)
          ->(target, &blk) { filter.filter target, &blk }
        else
          name, kind = @name, @kind
          ->(target, &blk) { filter.send "#{kind}_#{name}", target, &blk }
        end
      end

      def to_proc
        make_proc @filter
      end

    end

  end
end
