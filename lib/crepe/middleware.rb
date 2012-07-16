module Crepe
  module Middleware

    autoload :ContentNegotiation, 'crepe/middleware/content_negotiation'
    autoload :Head,               'crepe/middleware/head'
    autoload :RestfulStatus,      'crepe/middleware/restful_status'

  end
end
