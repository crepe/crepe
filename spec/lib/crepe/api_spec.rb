require 'spec_helper'
require 'crepe'

describe Crepe::API do

  describe '.param' do
    app { param(:action) { get { params[:action] } } }
    it 'wraps endpoints with a param-based path component' do
      get('/dig').body.should include 'dig'
    end
  end

  describe '.vendor' do
    app { vendor :pancake and get { 'OK' } }
    it 'sets vendor' do
      get('/').content_type.should eq 'application/vnd.pancake+json'
    end

    context 'embedded in another API' do
      before do
        inner = Class.new(Crepe::API) { get { vendor } }
        Object.const_set :Inner, inner
      end

      after do
        Object.send :remove_const, :Inner if Object.const_defined? :Inner
      end

      app { vendor :pancake and mount Inner }

      it 'carries over into the API' do
        get('/').body.should eq '"pancake"'
      end
    end
  end

  describe '.version' do
    app { version :v1 and get { 'OK' } }

    it 'adds a namespace' do
      get('/v1').should be_ok
    end

    it 'adds the version to content-type' do
      get('/v1').content_type.should eq 'application/vnd.crepe.v1+json'
    end

    context 'with a block' do
      app { version(:v1) { get { 'OK' } } and get { 'OK' } }
      it 'sets the version for endpoints inside the block' do
        get('/v1').content_type.should eq 'application/vnd.crepe.v1+json'
      end

      it 'does not set the version outside the block' do
        get('/').content_type.should eq 'application/json'
      end
    end
  end

end
