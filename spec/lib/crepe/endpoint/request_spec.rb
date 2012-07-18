require 'rack/mock'
require_relative '../../../../lib/crepe/endpoint/request'

describe Crepe::Endpoint::Request do
  subject(:request) {
    Crepe::Endpoint::Request.new env.update(Rack::MockRequest.env_for)
  }
  let(:env) { {} }

  describe '#headers' do
    it 'indexes with human-readable header keys' do
      env['HTTP_IF_NONE_MATCH'] = '"ETag!"'
      request.headers['If-None-Match'].should eq('"ETag!"')
    end
  end

  context 'HEAD requests' do
    before do
      env['REQUEST_METHOD'] = 'GET'
      env['crepe.original_request_method'] = 'HEAD'
    end

    describe '#method' do
      it 'references original methods when transformed earlier' do
        request.method.should eq('HEAD')
      end
    end

    describe '#head?' do
      it 'returns true' do
        request.should be_head
      end
    end
  end

  describe '#params' do
    it 'merges GET, POST, and path parameters' do
      request.stub GET: {'get'=>'true'}
      request.stub POST: {'post'=>'true'}
      request.stub path_parameters: {'path'=>'true'}
      request.params.should eq('get'=>'true', 'post'=>'true', 'path'=>'true')
    end
  end

  describe '#credentials' do
    it 'returns an array without credentials' do
      request.credentials.should be_empty
    end
  end
end
