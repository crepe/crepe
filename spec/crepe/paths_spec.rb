require 'spec_helper'

describe Crepe::API, 'paths' do
  app do
    scope '/users' do
      get

      param :id, constraints: { id: /\d+/ } do
        get
      end
    end

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

  it "routes known paths" do
    expect(get '/users').to be_successful
    expect(get '/users/1').to be_successful
    expect(get '/users/1/posts').to be_successful
    expect(get '/users/all').to be_successful
    expect(get '/users/1').to be_successful
    expect(get('/users/1/posts').body).to include 'active'
  end

  it "doesn't route unknown paths" do
    expect(get '/').to be_not_found
    expect(get '/v2/users/all').to be_not_found
    expect(get '/v1/users/none').to be_not_found
  end
end
