module Cape
  class Endpoint
    module Renderer

      autoload :Base,   'cape/endpoint/renderer/base'
      autoload :Simple, 'cape/endpoint/renderer/simple'
      autoload :Tilt,   'cape/endpoint/renderer/tilt'

    end
  end
end

