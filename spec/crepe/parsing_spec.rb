require 'spec_helper'

describe Crepe::Parser, 'parsing' do
  app do
    post do
      status :ok
      params[:ok]
    end
  end

  context 'an unsupported media type' do
    it 'renders Unsupported Media Type' do
      response = post '/', { ok: 'computer' }, {
        'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
      }
      expect(response.status).to eq 415
    end
  end

  context 'a registered, parseable media type' do
    app do
      parses(*Rack::Request::FORM_DATA_MEDIA_TYPES)
      post do
        status :ok
        request.body['ok']
      end
    end

    it 'parses properly' do
      response = post '/', { ok: 'computer' }, {
        'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
      }
      expect(response).to be_ok
      expect(response.body).to eq '"computer"'
    end
  end

  context 'invalid JSON' do
    it 'renders Bad Request' do
      response = post '/', '{', 'CONTENT_TYPE' => 'application/json'
      expect(response.status).to eq 400
    end
  end

  context 'valid JSON' do
    it 'parses properly' do
      response = post '/', '{"ok":"computer"}', {
        'CONTENT_TYPE' => 'application/json; charset=utf-8'
      }
      expect(response).to be_ok
      expect(response.body).to eq '"computer"'
    end
  end

  context 'a registered, unparseable media type' do
    app do
      parses :xml
      post do
        head :ok
        params[:ok]
      end
    end

    it 'passes the body through' do
      response = post '/', '<ok>computer</ok>', {
        'CONTENT_TYPE' => 'application/xml'
      }
      expect(response).to be_ok
      expect(response.body).to be_empty
    end
  end
end
