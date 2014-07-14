require 'active_support/core_ext/hash/indifferent_access'
require 'crepe/util'

module Crepe
  #--
  # Based on https://github.com/rails/strong_parameters, provides a security
  # proxy object for submitted parameters.
  #++
  class Params < BasicObject

    instance_methods.grep(/^[^_]/).each { |m| undef_method m }

    INSTANCE_METHODS = [:require, :permit, :permitted?, :permit!]

    # Raised when a required parameter is missing (see Crepe::Params#require).
    class Missing < ::IndexError

      attr_reader :data

      def initialize data
        @data = data
        super "Missing parameter: #{data[:missing]}"
      end

    end

    # Raised when an unpermitted parameter is found (see Crepe::Params#permit).
    class Invalid < ::StandardError

      attr_reader :data

      def initialize data
        @data = data
        super "Invalid parameter(s): #{data[:invalid].join ', '}"
      end

    end

    def initialize params = {}, permit = false, freeze = true
      @params = params.with_indifferent_access
      @permitted = permit
      @frozen = freeze
    end

    # Ensures that a parameter is present by returning the parameter at a given
    # +key+ or raising a <tt>Crepe::Params::Missing</tt> error.
    #
    # @param [Symbol, String] required_key the required parameter
    # @return [Object] the value at the required key
    # @raise [Crepe::Params::Missing] if the parameter is missing
    def require required_key
      self[required_key].presence or raise Missing, missing: required_key
    end

    # Returns a new {Crepe::Params} instance that includes only the given keys
    # and sets +permitted+ to +true+.
    #
    # @param [Array<Symbol, String>] secure_keys whitelisted keys
    # @return [Crepe::Params] a slice of the given keys
    def permit *secure_keys
      insecure_keys = keys - secure_keys.map(&:to_s)
      unless insecure_keys.empty?
        raise Invalid, invalid: insecure_keys, valid: secure_keys
      end
      slice(*secure_keys).permit!
    end

    # Whether or not the parameters have been permitted.
    #
    # @return [true, false] if the parameters have been permitted
    def permitted?
      @permitted
    end

    def frozen?
      @frozen
    end

    # Sets +permitted+ to +true+.
    #
    # @return [self]
    def permit!
      @permitted = true and self
    end

    def respond_to? method_name, include_private = false
      INSTANCE_METHODS.include? method_name or super
    end

    def to_h
      (frozen? ? dup : @params).to_h
    end
    alias to_hash to_h

    def dup
      ::Crepe::Params.new @params, permitted?, false
    end

    private

      def method_missing method_name, *args, &block
        value = _params.send method_name, *args, &block
        if value.is_a? ::Hash
          return ::Crepe::Params.new value, permitted?, frozen?
        end
        frozen? ? _deep_freeze(value) : value
      end

      def _params
        @_params ||= frozen? ? @params.dup.freeze : @params
      end

      def _deep_freeze value
        case value
          when ::Hash   then ::Crepe::Params.new value, permitted?, true
          when ::Array  then value.map { |v| _deep_freeze v }.freeze
          when ::String then value.dup.freeze
          else               value
        end
      end

  end
end
