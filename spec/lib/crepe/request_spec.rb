require 'rack/mock'
require_relative '../../../lib/crepe/request'

describe Crepe::Request do
  subject(:request) {
    described_class.new env.update Rack::MockRequest.env_for
  }
  let(:env) { {} }

  describe '#headers' do
    it 'indexes with human-readable header keys' do
      env['HTTP_IF_NONE_MATCH'] = '"ETag!"'
      expect(request.headers['If-None-Match']).to eq '"ETag!"'
    end
  end

  context 'HEAD requests' do
    before do
      env['REQUEST_METHOD'] = 'GET'
      env['crepe.original_request_method'] = 'HEAD'
    end

    it { is_expected.to be_head }
    it { is_expected.to be_get }

    context 'method' do
      subject { request.method }
      it { is_expected.to eq 'HEAD' }
    end
  end

  describe '#params' do
    it 'merges GET, POST, and path parameters' do
      allow(request).to receive(:GET).and_return 'get' => 'true'
      allow(request).to receive(:POST).and_return 'post'=> 'true'
      request.env['rack.routing_args'] = { 'path' => 'true' }
      params = { 'get' => 'true', 'post' => 'true', 'path' => 'true' }
      expect(request.params).to eq(params)
    end
  end

  describe '#credentials' do
    it 'returns an array without credentials' do
      expect(request.credentials).to be_empty
    end
  end
end
