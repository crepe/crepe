module Cape
  class Endpoint
    module Filter

      autoload :Acceptance, 'cape/endpoint/filter/acceptance'
      autoload :Parser,     'cape/endpoint/filter/parser'

    end
  end
end