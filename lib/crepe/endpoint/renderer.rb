module Crepe
  class Endpoint
    module Renderer

      # A RenderError can be used to indicate that rendering has failed for
      # some reason. More specific errors in a renderer should inherit from
      # this class so that a Crepe::API class can rescue all errors within
      # rendering by rescuing Endpoint::Renderer::RenderError.
      class RenderError < StandardError
      end

      autoload :Base,   'crepe/endpoint/renderer/base'
      autoload :Simple, 'crepe/endpoint/renderer/simple'
      autoload :Tilt,   'crepe/endpoint/renderer/tilt'

    end
  end
end

