require 'rack/response'

module Crepe
  # A lightweight endpoint response object used to generate a Rack response.
  class Response

    include Rack::Response::Helpers

    attr_accessor :status

    attr_accessor :headers

    attr_accessor :body

    def initialize
      @status = 200
      @headers = {}
      @body = nil
    end

    def finish
      headers['Cache-Control'] ||= cache_control_header
      [status, headers, [*body]]
    end

    def cache_control
      @cache_control ||= {}
    end

    private

    def cache_control_header
      return 'max-age=0, private, must-revalidate' if cache_control.empty?

      header = cache_control.map do |key, value|
        next unless value
        key = key.to_s.dasherize
        value == true ? key : "#{key}=#{value}"
      end

      header.join ', '
    end

  end
end
