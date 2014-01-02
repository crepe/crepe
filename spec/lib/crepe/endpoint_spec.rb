require 'active_support/json'
require 'ostruct'
require 'rack/mock'
require_relative '../../../lib/crepe/endpoint'

describe Crepe::Endpoint do
  let(:endpoint) do
    Class.new(described_class).tap do |endpoint|
      endpoint.config.update config
      endpoint.handle(&handler)
    end
  end
  let(:config) { {} }
  let(:handler) { proc { 'Hello, world!' } }
  let(:response) {
    status, headers, body = endpoint.call env
    OpenStruct.new status: status, headers: headers, body: body.join("\n")
  }
  let(:env) { Rack::MockRequest.env_for }

  describe '#format' do
    let(:instance) { endpoint.new.tap { |e| e.call env } }
    subject { instance.format }

    context 'with formats configured' do
      let(:config) { { formats: [:xml, :json] } }
      it { is_expected.to eq :xml }
    end

    context 'with a format parameter' do
      before { env['QUERY_STRING'] = 'format=json' }
      it { is_expected.to eq :json }
    end
  end

  describe '#headers' do
    let(:handler) { proc { headers['Awesome'] = 'You are awesome!' } }

    it 'become response headers' do
      expect(response.headers).to include 'Awesome' => 'You are awesome!'
    end
  end

  describe '#error!' do
    let(:handler) { proc { error! 404, 'Not found' } }

    it 'sets status code' do
      expect(response.status).to eq 404
    end

    it 'sets message' do
      expect(response.body).to include 'Not found'
    end
  end

  describe '#unauthorized!' do
    let(:handler) { proc { unauthorized! realm: 'Crepe' } }

    it 'returns 401 Unauthorized' do
      expect(response.status).to eq 401
      expect(response.body).to eq '{"error":{"message":"Unauthorized"}}'
    end

    it 'sets WWW-Authenticate header' do
      header = { 'WWW-Authenticate' => 'Basic realm="Crepe"' }
      expect(response.headers).to include header
    end

    context 'with a message' do
      let(:handler) { proc { unauthorized! 'Not Allowed', realm: 'Crepe' } }

      it 'returns the specified error message' do
        expect(response.body).to eq '{"error":{"message":"Not Allowed"}}'
      end
    end

    context 'with data' do
      let(:handler) { proc { unauthorized! extra: 'data' } }

      it 'returns the data' do
        json = '{"error":{"message":"Unauthorized","extra":"data"}}'
        expect(response.body).to eq json
      end
    end
  end
end
