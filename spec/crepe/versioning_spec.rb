require 'spec_helper'

describe Crepe::API, 'versioning' do

  context 'with path' do
    app do
      version :v1, with: :path do
        get
      end
    end

    it 'routes with the path' do
      get('/v1').should be_ok
    end
  end

  context 'with header' do
    app do
      version with: :header, vendor: :pancake

      version :v2 do
        get { :v2 }
      end

      version :v1 do
        get { :v1 }
      end
    end

    it 'routes to several versions at the same path' do
      get '/', {}, 'HTTP_ACCEPT' => 'application/vnd.pancake-v2+json'
      last_response.body.should include 'v2'
      get '/', {}, 'HTTP_ACCEPT' => 'application/vnd.pancake-v1+json'
      last_response.body.should include 'v1'
    end
  end

  context 'with query' do
    app do
      version with: :query, name: 'ver'

      version :v2 do
        get { :v2 }
      end

      version :v1 do
        get { :v1 }
      end
    end

    it 'routes to the version with a parameter' do
      get('/', ver: 'v2').body.should include 'v2'
      get('/', ver: 'v1').body.should include 'v1'
    end
  end

end
