require 'spec_helper'

describe Crepe::API, 'paths' do
  app do
    version :v2 do
      scope '/users' do
        get

        param :id, conditions: { id: /\d+/ } do
          get

          resource :posts do
            get
          end
        end
      end
    end

    version :v1 do
      namespace 'users' do
        get '/all'
      end
    end
  end

  it "routes known paths" do
    get('/v2/users').should be_successful
    get('/v2/users/1').should be_successful
    get('/v2/users/1/posts').should be_successful
    get('/v1/users/all').should be_successful
  end

  it "doesn't route unknown paths" do
    get('/').should be_not_found
    get('/v2/users/all').should be_not_found
  end
end
