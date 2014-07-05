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
    expect(get('/').body).to eq '"HI"'
  end

  it 'mounts Rack apps at paths' do
    expect(get('/ping').body).to eq 'OK'
  end

  it 'mounts Rack apps within namespaces' do
    expect(get('/pong').body).to eq 'KO'
  end
end
