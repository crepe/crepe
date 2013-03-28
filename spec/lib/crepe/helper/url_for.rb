require 'spec_helper'
require 'crepe'

describe Crepe::Helper::URLFor
  before { app.helper Crepe::Helper::URLFor }

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
