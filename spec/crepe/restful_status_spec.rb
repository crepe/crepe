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
        post('/post').status.should eq 201
      end
    else
      it "returns 200 OK for #{method.upcase} with content" do
        send(method, "/#{method}").status.should eq 200
      end
    end

    it "returns 204 No Content for #{method.upcase} without content" do
      send(method, "/empty/#{method}").status.should eq 204
    end

    it "returns the original status for #{method.upcase} if set explicitly" do
      send(method, "/explicit/#{method}").status.should eq 202
    end
  end
end
