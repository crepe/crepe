require 'active_support/all'

module Crepe

  autoload :API,        'crepe/api'
  autoload :Endpoint,   'crepe/endpoint'
  autoload :Filter,     'crepe/filter'
  autoload :Helper,     'crepe/helper'
  autoload :Middleware, 'crepe/middleware'
  autoload :Params,     'crepe/params'
  autoload :Renderer,   'crepe/renderer'
  autoload :Request,    'crepe/request'
  autoload :Response,   'crepe/response'
  autoload :Streaming,  'crepe/streaming'
  autoload :Util,       'crepe/util'
  autoload :VERSION,    'crepe/version'

end
