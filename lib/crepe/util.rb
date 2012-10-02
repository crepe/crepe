require 'active_support/core_ext/object/duplicable'

module Crepe
  module Util

    autoload :HashStack,      'crepe/util/hash_stack'
    autoload :ChainedInclude, 'crepe/util/chained_include'

    # Deeply duplicates values in the object passed in. If the object
    # is a Hash or Array, it recursively dups the object's values.
    def deep_dup object
      object = object.dup if object.duplicable?

      case object
        when Hash  then object.each { |k, v| object[k] = deep_dup v }
        when Array then object.map! { |o| deep_dup o }
      end

      object
    end

    # See `deeper_merge!`: returns a copy of the original hash, rather
    # than merging it in place.
    def deeper_merge hash, other_hash
      deeper_merge! hash.dup, other_hash
    end

    # Deeply merges the first hash with the second hash, concatenating
    # any array values that are shared across keys.
    def deeper_merge! hash, other_hash
      other_hash.each do |key, value|
        if hash[key].is_a?(Hash) && value.is_a?(Hash)
          hash[key] = deeper_merge hash[key], value
        elsif hash[key].is_a?(Array) && value.is_a?(Array)
          hash[key] += value
        else
          hash[key] = value
        end
      end

      hash
    end

    # Recursively freezes all keys and values.
    def deep_freeze hash
      hash.each do |key, value|
        case value
          when Hash  then deep_freeze value
          when Array then value.each { |v| deep_freeze v }
          else            value.freeze
        end
      end
      hash.freeze
    end

    def normalize_path! path
      path.squeeze! '/'
      path.sub! %r{/+\z}, ''
      path.sub! %r{/([.?])}, '\1'
      path.replace '/' if path.empty?
      path
    end

    extend self

  end
end
