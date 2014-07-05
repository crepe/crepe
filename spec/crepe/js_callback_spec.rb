require 'spec_helper'

describe Crepe::Middleware::JSCallback do

  app do
    get '*catch' do
      error! :not_found
    end
  end

  before { get '/anywhere', callback: 'say' }

  it 'renders JavaScript callback' do
    expect(last_response.body).to eq(
      '%{function}(%{body},%{headers},%{status})' % {
        function: 'say',
        body: { error: { message: 'Not Found' } }.to_json,
        headers: {
          contentType: 'application/json; charset=utf-8',
          cacheControl: 'max-age=0, private, must-revalidate'
        }.to_json,
        status: 404
      }
    )
  end

  it 'renders 200 OK' do
    expect(last_response).to be_ok
  end

  it 'renders application/javascript' do
    content_type = last_response.headers['Content-Type']
    expect(content_type).to eq 'application/javascript; charset=utf-8'
  end

  context 'with a custom callback param' do
    app do
      config[:middleware].delete Crepe::Middleware::JSCallback
      use Crepe::Middleware::JSCallback, :jsonp

      get do
        { hello: 'world' }
      end
    end

    it 'renders the callback param' do
      get '/', jsonp: 'say'

      expect(last_response.body).to eq(
        '%{function}(%{body},%{headers},%{status})' % {
          function: 'say',
          body: { hello: 'world' }.to_json,
          headers: {
            contentType: 'application/json; charset=utf-8',
            cacheControl: 'max-age=0, private, must-revalidate'
          }.to_json,
          status: 200
        }
      )
    end
  end

end
