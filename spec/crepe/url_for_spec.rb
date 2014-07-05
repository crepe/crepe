require 'spec_helper'

describe Crepe::Helper::URLFor, '#url_for' do

  app do
    respond_to :txt
    helper Crepe::Helper::URLFor
    get { url }
  end

  subject(:response) { get('/').body }

  it 'joins components' do
    app.let(:url) { url_for :hello, :world }
    expect(response).to eq 'http://example.org/hello/world'
  end

  it 'parameterizes objects' do
    app.let(:user) { Object.new.tap { |o| def o.to_param() 1 end } }
    app.let(:url) { url_for :users, user }
    expect(response).to eq 'http://example.org/users/1'
  end

  it 'normalizes the path' do
    app.let(:url) { url_for '/one', nil, '/two/', '//three///' }
    expect(response).to eq 'http://example.org/one/two/three'
  end

  it 'appends an extension' do
    app.let(:url) { url_for :index, format: :html }
    expect(response).to eq 'http://example.org/index.html'
  end

  it 'appends a query' do
    app.let(:url) { url_for hello: 'world' }
    expect(response).to eq 'http://example.org/?hello=world'
  end

  context 'requested with an extension' do
    subject(:response) { get('/.txt').body }

    it 'appends an extension' do
      app.let(:url) { url_for :robots }
      expect(response).to eq 'http://example.org/robots.txt'
    end
  end

end
