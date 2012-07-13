module Crepe
  module Middleware

    autoload :ContentNegotiation, 'crepe/middleware/content_negotiation'
    autoload :Format,             'crepe/middleware/format'
    autoload :Head,               'crepe/middleware/head'
    autoload :Pagination,         'crepe/middleware/pagination'
    autoload :RestfulStatus,      'crepe/middleware/restful_status'

  end
end
