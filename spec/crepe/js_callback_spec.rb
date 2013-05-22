require 'spec_helper'

describe Crepe::Filter::JSCallback do

  app do
    get '*catch' do
      error! :not_found
    end
  end

  before { get '/anywhere', callback: 'say' }

  it 'renders JavaScript callback' do
    last_response.body.should eq(
      '%{function}(%{body},%{headers},%{status});' % {
        function: 'say',
        body: { error: { message: 'Not Found' } }.to_json,
        headers: { contentType: 'application/json; charset=utf-8' }.to_json,
        status: 404
      }
    )
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
      skip_after Crepe::Filter::JSCallback
      after Crepe::Filter::JSCallback.new 'jsonp'

      get do
        { hello: 'world' }
      end
    end

    it 'renders the callback param' do
      get('/', jsonp: 'say').body.should eq(
        '%{function}(%{body},%{headers},%{status});' % {
          function: 'say',
          body: { hello: 'world' }.to_json,
          headers: { contentType: 'application/json; charset=utf-8' }.to_json,
          status: 200
        }
      )
    end
  end

end
