require 'spec_helper'

describe Crepe::API, 'RESTful status' do
  app do
    post   '/post'   do { created_at: Time.now } end
    put    '/put'    do { updated_at: Time.now } end
    patch  '/patch'  do { updated_at: Time.now } end
    delete '/delete' do { deleted_at: Time.now } end
    namespace :empty do
      post   '/post'
      put    '/put'
      patch  '/patch'
      delete '/delete'
    end
    namespace :explicit do
      post   '/post'   do status :accepted end
      put    '/put'    do status :accepted end
      patch  '/patch'  do status :accepted end
      delete '/delete' do status :accepted end
    end
  end

  %w[post put patch delete].each do |method|
    if method == 'post'
      it "returns 201 Created for POST with content" do
        expect(post('/post').status).to eq 201
      end
    else
      it "returns 200 OK for #{method.upcase} with content" do
        expect(send(method, "/#{method}").status).to eq 200
      end
    end

    it "returns 204 No Content for #{method.upcase} without content" do
      expect(send(method, "/empty/#{method}").status).to eq 204
    end

    it "returns the original status for #{method.upcase} if set explicitly" do
      expect(send(method, "/explicit/#{method}").status).to eq 202
    end
  end
end
