module Cape
  module Middleware

    autoload :ContentNegotiation, 'cape/middleware/content_negotiation'
    autoload :Format,             'cape/middleware/format'
    autoload :Head,               'cape/middleware/head'
    autoload :Pagination,         'cape/middleware/pagination'
    autoload :RestfulStatus,      'cape/middleware/restful_status'

  end
end
