require 'active_support/core_ext/hash/indifferent_access'
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
    end

    # Raised when an unpermitted parameter is found (see Crepe::Params#permit).
    class Invalid < ::StandardError
    end

    def initialize params = {}
      @params = ::HashWithIndifferentAccess.new params
      ::Crepe::Util.deep_freeze @params
      @permitted = false
    end

    def require required_key
      value = @params[required_key]
      unless value.is_a? ::Hash # Consider checking presence instead.
        raise Missing, required_key
      end
      ::Crepe::Params.new value
    end

    def permit *secure_keys
      insecure_keys = keys - secure_keys.map(&:to_s)
      raise Invalid, insecure_keys.join(', ') unless insecure_keys.empty?
      @permitted = true
      self
    end

    def permitted?
      @permitted
    end

    def dup
      @params.dup
    end

    def respond_to? method_name, include_private = false
      public_methods.grep(method_name) ||
        @params.respond_to?(method_name, include_private)
    end

    private

      def method_missing method_name, *args, &block
        value = @params.send method_name, *args, &block
        value.is_a?(::Hash) ? ::Crepe::Params.new(value) : value
      end

  end
end
