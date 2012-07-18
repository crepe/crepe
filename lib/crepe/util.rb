module Crepe
  module Util

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

    extend self

  end
end
