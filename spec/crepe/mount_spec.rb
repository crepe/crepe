require 'spec_helper'

describe Crepe::API, '.mount' do
  app do
    sub_api = Class.new Crepe::API do
      get { 'HI' }
    end

    mount sub_api

    mount -> env { [200, {}, ['OK']] } => '/ping'

    namespace :pong do
      mount -> env { [200, {}, ['KO']] }
    end
  end

  it 'mounts Rack apps in place' do
    get('/').body.should eq '"HI"'
  end

  it 'mounts Rack apps at paths' do
    get('/ping').body.should eq 'OK'
  end

  it 'mounts Rack apps within namespaces' do
    get('/pong').body.should eq 'KO'
  end
end
