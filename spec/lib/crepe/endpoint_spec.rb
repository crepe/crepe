require 'active_support/json'
require 'ostruct'
require 'rack/mock'
require_relative '../../../lib/crepe/endpoint'

describe Crepe::Endpoint do
  let(:endpoint) { described_class.new config }
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
      it { should eq :xml }
    end

    context 'with a format parameter' do
      before { env['QUERY_STRING'] = 'format=json' }
      it { should eq :json }
    end
  end

  describe '#headers' do
    let(:handler) { proc { headers['Awesome'] = 'You are awesome!' } }

    it 'become response headers' do
      response.headers.should include 'Awesome'=>'You are awesome!'
    end
  end

  describe '#error!' do
    let(:handler) { proc { error! 404, 'Not found' } }

    it 'sets status code' do
      response.status.should eq 404
    end

    it 'sets message' do
      response.body.should include 'Not found'
    end
  end

  describe '#unauthorized!' do
    let(:handler) { proc { unauthorized! realm: 'Crepe' } }

    it 'returns 401 Unauthorized' do
      response.status.should eq 401
      response.body.should eq '{"error":{"message":"Unauthorized"}}'
    end

    it 'sets WWW-Authenticate header' do
      response.headers.should include 'WWW-Authenticate'=>'Basic realm="Crepe"'
    end

    context 'with a message' do
      let(:handler) { proc { unauthorized! 'Not Allowed', realm: 'Crepe' } }

      it 'returns the specified error message' do
        response.body.should eq '{"error":{"message":"Not Allowed"}}'
      end
    end

    context 'with data' do
      let(:handler) { proc { unauthorized! extra: 'data' } }

      it 'returns the data' do
        json = '{"error":{"extra":"data","message":"Unauthorized"}}'
        response.body.should eq json
      end
    end
  end

  describe '#url_for' do
    context 'with an request extension' do
      app { get(:index) { url_for :users } }
      it 'renders an extension when requests use extensions' do
        get('/index.json').body.should eq '"http://example.org/users.json"'
      end
    end

    context 'with a format' do
      app { get { url_for :users, format: :csv } }
      it 'renders an extension when options include format' do
        get('/').body.should eq '"http://example.org/users.csv"'
      end
    end

    context 'with query parameters' do
      app { get { url_for :users, state: 'active' } }
      it 'renders a query string' do
        get('/').body.should eq '"http://example.org/users?state=active"'
      end

    context 'with an object that responds to to_param' do
      app do
        get do
          user = Object.new.tap { |u| def u.to_param() 1 end }
          url_for :users, user, :posts
        end
      end
      it 'parameterizes the object' do
        get('/').body.should eq '"http://example.org/users/1/posts"'
      end
    end

    context 'versioning' do
      app { version(:v2) { get { url_for :users } } }

      it 'renders the URL with a path-based version' do
        get('/v2').body.should eq '"http://example.org/v2/users"'
      end

      it 'renders the URL with a query-based version' do
        get('/?v=v2').body.should eq '"http://example.org/users?v=v2"'
      end

      it 'renders the URL without a version' do
        get('/', {}, 'HTTP_ACCEPT' => 'application/vnd.crepe-v2')
        last_response.body.should eq '"http://example.org/users"'
      end
    end
  end
end
