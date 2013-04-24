require 'active_support/all'

module Crepe

  autoload :Accept,     'crepe/accept'
  autoload :API,        'crepe/api'
  autoload :Config,     'crepe/config'
  autoload :Endpoint,   'crepe/endpoint'
  autoload :Filter,     'crepe/filter'
  autoload :Helper,     'crepe/helper'
  autoload :Middleware, 'crepe/middleware'
  autoload :Params,     'crepe/params'
  autoload :Parser,     'crepe/parser'
  autoload :Renderer,   'crepe/renderer'
  autoload :Request,    'crepe/request'
  autoload :Response,   'crepe/response'
  autoload :Streaming,  'crepe/streaming'
  autoload :Util,       'crepe/util'
  autoload :VERSION,    'crepe/version'

end
