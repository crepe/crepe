ENV['CREPE_ENV']  ||= ENV['RACK_ENV'] ||= 'development'
ENV['CREPE_ROOT'] ||= Dir.pwd

require 'active_support/all'

# Crepe: the thin API stack.
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

    attr_writer :logger

    # Crepe's logging interface.
    #
    #   Crepe.logger.debug 'testing: one, two, three...'
    #
    # @return [Logger]
    def logger
      @logger ||= Logger.new((STDOUT if Crepe.env.development?))
    end

    # The app's current environment. Defaults to "development" and can be
    # overridden with an environment variable: either +CREPE_ENV+ or
    # +RACK_ENV+.
    #
    #   Crepe.env.production?
    #
    # @return [ActiveSupport::StringInquirer]
    def env
      @env ||= ActiveSupport::StringInquirer.new ENV['CREPE_ENV']
    end

    # The app's root directory. Defaults to the working directory when the app
    # was launched, but can be overridden with the +CREPE_ROOT+ environment
    # variable.
    #
    #   database_yml = Crepe.root.join 'config', 'database.yml'
    #
    # @return [Pathname]
    def root *path
      (@root ||= Pathname.new(ENV['CREPE_ROOT'])).join(*path)
    end

  end

end
