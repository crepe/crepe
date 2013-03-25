require 'rspec'
require 'rack/test'
$: << File.expand_path('../../config', __FILE__)

RSpec.configure do |config|
  config.include Rack::Test::Methods

  def app &block
    let(:app) { Class.new Crepe::API, &block }
  end

  def describes_middleware middleware = described_class
    let(:core)    { -> env { [status, headers, body] } }

    let(:status)  { 200 }
    let(:headers) { {} }
    let(:body)    { ['Hello, world!'] }

    let :app do
      app = Rack::Builder.new
      app.use middleware
      app.run core
      app.to_app
    end
  end
end
