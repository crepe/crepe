require 'rack/mime'

module Crepe
  # A collection of helper methods Crepe uses internally.
  module Util

    module_function

    # Recursively dups hashes and arrays.
    #
    # @param [Hash, Array, Object] value the object to recursively dup
    # @return [Hash, Array, Object] a duplicate hash or array (with any nested
    #   hashes or arrays duplicated, as well), or the original object
    def deep_collection_dup value
      case value
        when Hash
          value.each_with_object value.dup do |(k, v), h|
            h[deep_collection_dup k] = deep_collection_dup v
          end
        when Array then value.map { |v| deep_collection_dup v }
        else            value
      end
    end

    # Recursively merges one hash with another, merging any nested hash value.
    #
    # @param [Hash] hash the hash whose values take less precedence
    # @param [Hash] other_hash the hash whose values take greater precedence
    # @return [Hash] a new, merged hash
    # @see #deep_merge!
    def deep_merge hash, other_hash
      deep_merge! deep_collection_dup(hash), other_hash
    end

    # Recursively merges one hash in place with another, merging any nested
    # hash value.
    #
    # @param [Hash] hash the hash whose values take less precedence
    # @param [Hash] other_hash the hash whose values take greater precedence
    # @return [Hash] the original hash, merged
    # @see #deep_merge
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

    # Normalizes a given path by inserting a leading slash if none exists, and
    # deleting repeating and trailing slashes.
    #
    #   Util.normalize_path! 'the//road/less/traveled/by/'
    #   # => "/the/road/less/traveled/by"
    #
    # @param [String] a path to be normalized
    # @return [String] a normalized path
    # @see #normalize_path!
    def normalize_path path
      normalize_path! path.dup
    end

    # Normalizes a given path in place by inserting a leading slash if none
    # exists, and deleting repeating and trailing slashes.
    #
    #   path = 'the//road/less/traveled/by/'
    #   Util.normalize_path! path
    #   path
    #   # => "/the/road/less/traveled/by"
    #
    # @param [String] a path to be normalized
    # @return [String] the original path, normalized
    # @see #normalize_path
    def normalize_path! path
      path.squeeze! '/'
      path.chomp! '/'
      path.prepend '/' unless path.start_with? '/'
      path
    end

    # Returns an array of media types for a given array of formats.
    #
    # @param [Array<Symbol, String>] formats a list of formats
    # @return [Array<String>] a list of media types
    # @see #media_type
    def media_types formats
      formats.map(&method(:media_type))
    end

    # Returns the media type for a given format.
    #
    #   Util.media_type :json # => "application/json"
    #
    # @param [Symbol, String] format a format
    # @return [String] a media type
    # @see #media_types
    def media_type format
      Rack::Mime.mime_type ".#{format}", format
    end

  end
end
