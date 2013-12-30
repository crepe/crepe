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
      request.headers['If-None-Match'].should eq '"ETag!"'
    end
  end

  context 'HEAD requests' do
    before do
      env['REQUEST_METHOD'] = 'GET'
      env['crepe.original_request_method'] = 'HEAD'
    end

    it { should be_head }
    it { should be_get }

    context 'method' do
      subject { request.method }
      it { should eq 'HEAD' }
    end
  end

  describe '#params' do
    it 'merges GET, POST, and path parameters' do
      request.stub GET: {'get'=>'true'}
      request.stub POST: {'post'=>'true'}
      request.env['rack.routing_args'] = {'path'=>'true'}
      request.params.should eq('get'=>'true', 'post'=>'true', 'path'=>'true')
    end
  end

  describe '#credentials' do
    it 'returns an array without credentials' do
      request.credentials.should be_empty
    end
  end
end
