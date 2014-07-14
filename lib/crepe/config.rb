module Crepe
  # A Hash-like object that scopes state changes using an underlying stack.
  class Config

    # Initializes a {Config} object with a given hash.
    #
    # @param [Hash] first The basic, "root" hash
    def initialize first = {}
      @stack = Array.wrap first
    end

    delegate :pop, :push, :<<, :last,
      to: :stack

    delegate :[], :[]=, :keys, :update,
      to: :last

    # Returns a stack of values for the given hash key.
    #
    # @param [Symbol] key a hash key
    # @return [Array] the stack of values for the given key
    def all key
      stack.select { |l| l.key? key }.map { |l| l[key] }.flatten 1
    end

    # Pushes a hash onto the stack and pops it after executing a block of code
    # when given.
    #
    # @param [Hash] scoped a hash to push onto the stack
    # @return [void]
    def scope **scoped
      return update scoped unless block_given?
      push Util.deep_merge to_h, scoped
      yield
      pop
    end

    # Returns a flattened hash from current stack of hashes.
    #
    # @return [Hash]
    def to_hash
      stack.inject { |h, layer| Util.deep_merge h, layer }
    end
    alias to_h to_hash

    # Returns a new {Config} object with a shallowly-duped stack.
    #
    # @return [Config]
    def dup
      self.class.new stack.dup
    end

    # Returns a new {Config} object with a deeply-duped stack.
    #
    # @return [Config]
    # @see Util.deep_collection_dup
    def deep_collection_dup
      self.class.new Util.deep_collection_dup stack
    end

    attr_reader :stack
    protected :stack

  end
end
