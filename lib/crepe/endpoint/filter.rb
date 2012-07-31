module Crepe
  class Endpoint
    module Filter

      autoload :Acceptance, 'crepe/endpoint/filter/acceptance'
      autoload :Parser,     'crepe/endpoint/filter/parser'

    end
  end
end
