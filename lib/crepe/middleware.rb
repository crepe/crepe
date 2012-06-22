module Crepe
  module Middleware

    autoload :Head,          'crepe/middleware/head'
    autoload :Format,        'crepe/middleware/format'
    autoload :Pagination,    'crepe/middleware/pagination'
    autoload :RestfulStatus, 'crepe/middleware/restful_status'

  end
end
