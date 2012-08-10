module Cape
  class Endpoint
    module Renderer

      # A RenderError can be used to indicate that rendering has failed for
      # some reason. More specific errors in a renderer should inherit from
      # this class so that a Cape::API class can rescue all errors within
      # rendering by rescuing Endpoint::Renderer::RenderError.
      class RenderError < StandardError; end

      autoload :Base,   'cape/endpoint/renderer/base'
      autoload :Simple, 'cape/endpoint/renderer/simple'
      autoload :Tilt,   'cape/endpoint/renderer/tilt'

    end
  end
end

