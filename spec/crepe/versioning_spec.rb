require 'spec_helper'

describe Crepe::API, 'versioning' do

  context 'with path' do
    app do
      version :v1, with: :path do
        get
      end
    end

    it 'routes with the path' do
      expect(get '/v1').to be_ok
    end
  end

  context 'with header' do
    app do
      version with: :header, vendor: :pancake, default: :v2

      version :v2 do
        get { :v2 }
      end

      version :v1 do
        get { :v1 }
      end
    end

    it 'routes to several versions at the same path' do
      get '/', {}, 'HTTP_ACCEPT' => 'application/vnd.pancake-v2+json'
      expect(last_response.body).to include 'v2'
      get '/', {}, 'HTTP_ACCEPT' => 'application/vnd.pancake-v1+json'
      expect(last_response.body).to include 'v1'
    end

    it 'defaults to the specified version' do
      expect(get('/').body).to include 'v2'
    end
  end

  context 'with query' do
    app do
      version with: :query, name: 'ver'

      version :v1 do
        get { :v1 }
      end

      version :v2 do
        get { :v2 }
      end
    end

    it 'routes to the version with a parameter' do
      expect(get('/', ver: 'v2').body).to include 'v2'
      expect(get('/', ver: 'v1').body).to include 'v1'
    end

    it 'defaults to the first specified version' do
      expect(get('/').body).to include 'v1'
    end
  end

end
