require 'spec_helper'

describe Crepe::API, '.mount' do
  app do
    mount -> env { [200, {}, ['OK']] } => '/ping'

    namespace :pong do
      mount -> env { [200, {}, ['KO']] }
    end

    api = Class.new Crepe::API do
      get do
        greeting
      end
    end
    mount api

    helper do
      def greeting
        'Hello, world!'
      end
    end
  end

  it 'mounts Rack apps at paths' do
    get('/ping').body.should eq 'OK'
  end

  it 'mounts Rack apps within namespaces' do
    get('/pong').body.should eq 'KO'
  end

  it 'mounts Crepe::APIs and extends their endpoints' do
    get('/').body.should include 'Hello, world!'
  end
end
