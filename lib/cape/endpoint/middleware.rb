class Cape::Endpoint
  module Middleware

    autoload :Format,             'cape/endpoint/middleware/format'
    autoload :Pagination,         'cape/endpoint/middleware/pagination'

  end
end
