module Crepe
  class Endpoint
    module Renderer

      autoload :Base,   'crepe/endpoint/renderer/base'
      autoload :Simple, 'crepe/endpoint/renderer/simple'
      autoload :Tilt,   'crepe/endpoint/renderer/tilt'

    end
  end
end

