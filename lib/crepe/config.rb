module Crepe
  # A Hash-like object that scopes state changes using an underlying stack.
  class Config

    def initialize first = {}
      @stack = Array.wrap first
    end

    delegate :pop, :push, :<<, :last,
      to: :stack

    delegate :[], :[]=, :keys, :update,
      to: :last

    def all key
      stack.select { |l| l.key? key }.map { |l| l[key] }.flatten 1
    end

    def scope **scoped
      return update scoped unless block_given?
      push Util.deep_merge to_h, scoped
      yield
      pop
    end

    def to_hash
      stack.inject { |h, layer| Util.deep_merge h, layer }
    end
    alias to_h to_hash

    def dup
      self.class.new stack.dup
    end

    def deep_collection_dup
      self.class.new Util.deep_collection_dup stack
    end

    attr_reader :stack
    protected :stack

  end
end
