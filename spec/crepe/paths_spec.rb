require 'spec_helper'

describe Crepe::API, 'paths' do
  app do
    version :v2 do
      scope '/users' do
        get

        param :id, constraints: { id: /\d+/ } do
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

        param id: /\d+/ do
          get

          get :posts, filter: 'active' do
            params[:filter]
          end
        end
      end
    end
  end

  it "routes known paths" do
    get('/v2/users').should be_successful
    get('/v2/users/1').should be_successful
    get('/v2/users/1/posts').should be_successful
    get('/v1/users/all').should be_successful
    get('/v1/users/1').should be_successful
    get('/v1/users/1/posts').body.should include 'active'
  end

  it "doesn't route unknown paths" do
    get('/').should be_not_found
    get('/v2/users/all').should be_not_found
    get('/v1/users/none').should be_not_found
  end
end
