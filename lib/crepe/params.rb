require 'crepe/util'

module Crepe
  #--
  # Based on https://github.com/rails/strong_parameters, provides a security
  # proxy object for submitted parameters.
  #++
  class Params < BasicObject

    instance_methods.grep(/^[^_]/).each { |m| undef_method m }

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

    def initialize params = {}, permitted = false
      @params = ::Crepe::Util.deep_freeze params.with_indifferent_access
      @permitted = permitted
    end

    def require required_key
      self[required_key].presence or raise Missing, missing: required_key
    end

    def permit *secure_keys
      insecure_keys = keys - secure_keys.map(&:to_s)
      unless insecure_keys.empty?
        raise Invalid, invalid: insecure_keys, valid: secure_keys
      end
      @permitted = true
      self
    end

    def permitted?
      @permitted
    end

    def respond_to? method_name, include_private = false
      [:require, :permit, :permitted?].include? method_name or super
    end

    def to_h
      @params.to_h
    end
    alias to_hash to_h

    private

      def method_missing method_name, *args, &block
        value = @params.send method_name, *args, &block
        value.is_a?(::Hash) ? ::Crepe::Params.new(value, permitted?) : value
      end

  end
end
