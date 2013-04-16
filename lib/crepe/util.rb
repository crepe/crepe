module Crepe
  module Util

    module_function

    def deep_dup value
      case value
        when Hash
          value.each_with_object value.dup do |(k, v), h|
            h[deep_dup(k)] = deep_dup v
          end
        when Array then value.map { |v| deep_dup v }
        else            value
      end
    end

    # See `deeper_merge!`: returns a copy of the original hash, rather
    # than merging it in place.
    def deep_merge hash, other_hash
      deep_merge! deep_dup(hash), other_hash
    end

    # Deeply merges the first hash with the second hash, concatenating
    # any array values that are shared across keys.
    def deep_merge! hash, other_hash
      other_hash.each do |key, value|
        if hash[key].is_a?(Hash) && value.is_a?(Hash)
          hash[key] = deep_merge hash[key], value
        else
          hash[key] = value
        end
      end

      hash
    end

    # Recursively freezes all keys and values.
    def deep_freeze value
      case value
        when Hash   then value.freeze.each_value { |v| deep_freeze v }
        when Array  then value.freeze.each { |v| deep_freeze v }
        when String then value.freeze
      end
      value
    end

    def normalize_path path
      normalize_path! path.dup
    end

    def normalize_path! path
      path.squeeze! '/'
      path.chomp! '/'
      path.start_with?('/') ? path : '/' + path
    end

  end
end
