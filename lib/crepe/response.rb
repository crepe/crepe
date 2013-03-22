require 'rack/response'

module Crepe
  class Response

    include Rack::Response::Helpers

    attr_accessor :status

    attr_accessor :body

    def initialize
      @status = 200
      @headers = {}
      @body = nil
    end

    def finish
      [status, headers, [*body]]
    end

  end
end
