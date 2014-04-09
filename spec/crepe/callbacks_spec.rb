require 'spec_helper'

describe Crepe::Endpoint, 'callbacks' do
  app do
    namespace :before do
      before { throw :halt, 'before' }
      get do
        'during'
      end
    end

    before   { @variable = '' }
    namespace :around do
      around do |handle|
        @variable << 'before1'
        result = handle.call;
        response.body = nil;
        render result + ' after1'
      end

      around do |handle|
        @variable << ' before2'
        result = handle.call;
        response.body = nil;
        result + ' after2'
      end

      get do
        "#{@variable} during"
      end
    end

    namespace :after do
      after { response.body = nil; render 'after' }
      get do
        'during'
      end
    end

    namespace :many do
      before { @variable << '1' }
      around { |handler|
        @variable << '2'
        @variable << handler.call
        @variable << '3'
      }
      after  { @variable << '4' }
      after  { response.body = nil; render @variable }

      get do
        'during'
      end
    end

    namespace :conditional do
      let(:always)    { true }
      let(:never)     { false }
      let(:sometimes) { request.params.key? 'on' }

      before(if: :always)    { @variable << '1' }
      before(if: :never)     { @variable << '2' }
      around(if: :sometimes) { |handler|
        @variable << '3'
        @variable << handler.call
        @variable << '4'
      }
      after(unless: :never)  { @variable << '5' }
      after(unless: :always) { @variable << '6' }
      after { response.body = nil; render @variable }

      get do
        'during'
      end

      namespace :string do
        before(if:     "request.params.key? 'on' ") { @variable << 'on' }
        before(unless: "request.params.key? 'on' ") { @variable << 'off' }
        after { response.body = nil; render @variable }

        get do
          'during'
        end
      end
    end
  end

  it 'runs before endpoint handlers' do
    get('/before').body.should eq '"before"'
  end

  it 'runs around endpoint handlers' do
    get('/around').body.should eq '"before1 before2 during after2 after1"'
  end

  it 'runs after endpoint handlers' do
    get('/after').body.should eq '"after"'
  end

  it 'runs series of callbacks' do
    get('/many').body.should eq '"12during34"'
  end

  it 'runs series of callbacks only when conditions match' do
    get('/conditional').body.should eq '"15"'
    get('/conditional?on').body.should eq '"13during45"'
  end

  it 'evaluates string conditions with endpoint binding' do
    get('/conditional/string').body.should eq '"1off5"'
    get('/conditional/string?on').body.should eq '"13onduring45"'
  end
end
