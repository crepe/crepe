require 'spec_helper'

describe Crepe::API, 'paths' do
  app do
    version :v2 do
      scope '/users' do
        get

        param :id, constraints: { id: /\d+/ } do
          get

          scope :posts do
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
    expect(get '/v2/users').to be_successful
    expect(get '/v2/users/1').to be_successful
    expect(get '/v2/users/1/posts').to be_successful
    expect(get '/v1/users/all').to be_successful
    expect(get '/v1/users/1').to be_successful
    expect(get('/v1/users/1/posts').body).to include 'active'
  end

  it "doesn't route unknown paths" do
    expect(get '/').to be_not_found
    expect(get '/v2/users/all').to be_not_found
    expect(get '/v1/users/none').to be_not_found
  end
end
