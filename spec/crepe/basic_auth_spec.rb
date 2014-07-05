require 'spec_helper'

describe Crepe::API, '.basic_auth' do
  app do
    get

    namespace :admin do
      basic_auth do |username, password|
        username == 'admin' && password == 'secret'
      end

      get

      namespace :sudo do
        basic_auth do |username, password|
          username == 'root' && password == '53cr37'
        end

        get
      end
    end
  end

  it "doesn't apply outside scopes" do
    expect(get '/').to be_ok
  end

  it "denies access" do
    expect(get('/admin').status).to eq 401
  end

  it "accepts valid credentials" do
    basic_authorize 'admin', 'secret'
    expect(get '/admin').to be_ok
  end

  it "accepts nested credentials" do
    basic_authorize 'root', '53cr37'
    expect(get '/admin/sudo').to be_ok
  end
end
