ENV['CREPE_ENV']  ||= ENV['RACK_ENV'] ||= 'development'
ENV['CREPE_ROOT'] ||= Dir.pwd

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

  class << self

    def env
      @env ||= ActiveSupport::StringInquirer.new ENV['CREPE_ENV']
    end

    def root *path
      (@root ||= Pathname.new(ENV['CREPE_ROOT'])).join(*path)
    end

  end

end
