module Cape
  module Middleware

    autoload :ContentNegotiation, 'cape/middleware/content_negotiation'
    autoload :Head,               'cape/middleware/head'
    autoload :RestfulStatus,      'cape/middleware/restful_status'

  end
end
