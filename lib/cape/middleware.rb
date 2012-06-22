module Cape
  module Middleware

    autoload :Head,          'cape/middleware/head'
    autoload :Format,        'cape/middleware/format'
    autoload :Pagination,    'cape/middleware/pagination'
    autoload :RestfulStatus, 'cape/middleware/restful_status'

  end
end
