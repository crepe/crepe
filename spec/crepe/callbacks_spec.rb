require 'spec_helper'

describe Crepe::Endpoint, 'callbacks' do
  app do
    namespace :before do
      before { throw :halt, 'before' }
      get do
        'during'
      end
    end

    namespace :after do
      after { response.body = nil; render 'after' }
      get do
        'during'
      end
    end

    before   { @variable = '1' }
    namespace :many do
      before { @variable << '2' }
      after  { @variable << '3' }
      after  { response.body = nil; render @variable }
      get do
        'during'
      end
    end
  end

  it 'runs before endpoint handlers' do
    expect(get('/before').body).to include 'before'
  end

  it 'runs after endpoint handlers' do
    expect(get('/after').body).to include 'after'
  end

  it 'runs series of callbacks' do
    expect(get('/many').body).to include '123'
  end
end
