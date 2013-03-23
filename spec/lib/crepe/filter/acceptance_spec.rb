require 'ostruct'
require 'rack/mock'
require_relative '../../../../lib/crepe/endpoint'

describe Crepe::Filter::Acceptance do
  subject { described_class }

  let(:env) {
    Rack::MockRequest.env_for
  }
  let(:endpoint) {
    endpoint = Crepe::Endpoint.new formats: %w[json]
    endpoint.instance_variable_set :@env, env
    endpoint
  }

  context 'unacceptable content' do
    it 'renders Not Acceptable' do
      env['rack.routing_args'] = { format: 'xml' }
      endpoint.should_receive(:error!).with(
        :not_acceptable, accepts: %w[application/json]
      )
      subject.filter endpoint
    end
  end
end
