require 'spec_helper'

describe Crepe::Filter::JSONP do

  app do
    get '*catch' do
      error! :not_found
    end
  end

  before { get '/anywhere', callback: 'say' }

  it 'renders JSONP' do
    last_response.body.should eq 'say({"error":{"message":"Not Found"}});'
  end

  it 'renders 200 OK' do
    last_response.status.should eq 200
  end

  it 'renders application/javascript' do
    content_type = last_response.headers['Content-Type']
    content_type.should eq 'application/javascript; charset=utf-8'
  end

  context 'with a custom callback param' do
    app do
      skip_after Crepe::Filter::JSONP
      after Crepe::Filter::JSONP.new 'jsonp'

      get do
        { hello: 'world' }
      end
    end

    it 'renders the callback param' do
      get('/', jsonp: 'say').body.should eq 'say({"hello":"world"});'
    end
  end

end
