ENV['RACK_ENV'] = 'test'

require 'rspec'
require 'rack/test'
$: << File.expand_path('../config', __dir__)

require 'crepe'

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.expect_with :rspec do |expectations|
    # Enable only the newer, non-monkey-patching expect syntax.
    expectations.syntax = :expect
  end

  def api base = Crepe::API, &block
    Class.new base, &block
  end

  def app &block
    let(:app) { api(&block) }
  end

  def describes_middleware middleware = described_class, except: []
    except = [*except]

    unless except.include? :core
      let(:core)    { -> env { [status, headers, body] } }
    end

    let(:status)  { 200 }               unless except.include? :status
    let(:headers) { {} }                unless except.include? :status
    let(:body)    { ['Hello, world!'] } unless except.include? :body

    unless except.include? :app
      let :app do
        app = Rack::Builder.new
        app.use middleware
        app.run core
        app.to_app
      end
    end
  end
end
