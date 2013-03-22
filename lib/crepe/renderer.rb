module Crepe
  module Renderer

    # A RenderError can be used to indicate that rendering has failed for
    # some reason. More specific errors in a renderer should inherit from
    # this class so that a Crepe::API class can rescue all errors within
    # rendering by rescuing Crepe::Renderer::RenderError.
    class RenderError < StandardError
    end

    autoload :Base,   'crepe/renderer/base'
    autoload :Simple, 'crepe/renderer/simple'
    autoload :Tilt,   'crepe/renderer/tilt'

  end
end

