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

      attr_reader :key

      def initialize key
        @key = key
        super "Missing parameter: #{key}"
      end

    end

    # Raised when an unpermitted parameter is found (see Crepe::Params#permit).
    class Invalid < ::StandardError

      attr_reader :keys

      def initialize keys
        @keys = keys
        super "Invalid parameter(s): #{keys.join ', '}"
      end

    end

    def initialize params = {}, permitted = false
      @params = ::HashWithIndifferentAccess.new params
      ::Crepe::Util.deep_freeze @params
      @permitted = permitted
    end

    def require required_key
      fetch(required_key) { raise Missing, required_key }
    end

    def permit *secure_keys
      insecure_keys = keys - secure_keys.map(&:to_s)
      raise Invalid, insecure_keys unless insecure_keys.empty?
      @permitted = true
      self
    end

    def permitted?
      @permitted
    end

    def dup
      ::Crepe::Params.new @params.dup, @permitted
    end

    def respond_to? method_name, include_private = false
      [:require, :permit, :permitted?].include? method_name or super
    end

    private

      def method_missing method_name, *args, &block
        value = @params.send method_name, *args, &block
        value.is_a?(::Hash) ? ::Crepe::Params.new(value, @permitted) : value
      end

  end
end
