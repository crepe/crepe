require 'active_support/json'
require 'ostruct'
require 'rack/mock'
require_relative '../../../lib/cape/endpoint'

describe Cape::Endpoint do
  let(:endpoint) { Cape::Endpoint.new config }
  let(:config) { { handler: handler } }
  let(:handler) { proc { 'Hello, world!' } }
  let(:response) {
    status, headers, body = endpoint.call env
    OpenStruct.new status: status, headers: headers, body: body.join("\n")
  }
  let(:env) { Rack::MockRequest.env_for }

  describe '#format' do
    subject { endpoint.format }
    before { endpoint.instance_variable_set :@env, env }

    context 'with formats configured' do
      let(:config) { { formats: %w[xml json] } }
      it { should eq(:xml) }
    end

    context 'with a format parameter' do
      before { env['QUERY_STRING'] = 'format=json' }
      it { should eq(:json) }
    end
  end

  describe '#headers' do
    let(:handler) { proc { headers['Awesome'] = 'You are awesome!' } }

    it 'become response headers' do
      response.headers.should include('Awesome'=>'You are awesome!')
    end
  end

  describe '#error!' do
    let(:handler) { proc { error! 404, 'Not found' } }

    it 'sets status code' do
      response.status.should eq(404)
    end

    it 'sets message' do
      response.body.should include('Not found')
    end
  end

  describe '#unauthorized!' do
    let(:handler) { proc { unauthorized! realm: 'Cape' } }

    it 'returns 401 Unauthorized' do
      response.status.should eq 401
      response.body.should eq('{"error":{"message":"Unauthorized"}}')
    end

    it 'sets WWW-Authenticate header' do
      response.headers.should include(
        'WWW-Authenticate'=>'Basic realm="Cape"'
      )
    end

    context 'with a message' do
      let(:handler) { proc { unauthorized! 'Not Allowed', realm: 'Cape' } }

      it 'returns the specified error message' do
        response.body.should eq('{"error":{"message":"Not Allowed"}}')
      end
    end

    context 'with data' do
      let(:handler) { proc { unauthorized! extra: 'data' } }

      it 'returns the data' do
        json = '{"error":{"extra":"data","message":"Unauthorized"}}'
        response.body.should eq(json)
      end
    end
  end
end
