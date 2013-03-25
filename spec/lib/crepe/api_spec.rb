require 'spec_helper'
require 'crepe'

describe Crepe::API do

  describe '.use' do
    let(:app)    { Class.new base, &routes }
    let(:base)   { Class.new Crepe::API, &routes }
    let(:routes) { proc { get { head } } }

    let(:middleware) do
      Class.new do
        def initialize app, *args, &block
          @app, @args, @block = app, args, block || ->{}
        end

        def call env
          [200, {}, [*@args, *@block.call, *@app.call(env)[2]]]
        end
      end
    end

    before do
      app.use(middleware, 1, 2) { 3 }
    end

    it 'accepts middleware, args, and block' do
      get('/').body.should eq '123'
    end

    context 'in an inherited app' do
      let(:base) { super().tap {|b| b.use middleware, 0 } }

      it 'is used in endpoints in the inheriting API' do
        get('/').body.should eq '0123'
      end
    end

    context 'in a mounted app' do
      let(:app2) { Class.new(base, &routes) }

      before do
        app2.use middleware, 4
        app.mount app2, at: '/mounted'
      end

      it 'is used in mounted endpoints' do
        get('/mounted').body.should eq '1234'
      end

      it 'is not used in the outer API endpoints' do
        get('/').body.should eq '123'
      end

      context 'that mounts another app that mounts another, etc' do
        let(:app3) { Class.new(base, &routes) }

        before do
          app2.mount app3, at: '/again'
          app3.mount base, at: '/andagain'
        end

        context 'with the same middleware and args' do
          before do
            app3.use middleware, 4
            base.use middleware, 4
          end

          it 'is not used again' do
            get('/mounted/again').body.should eq '1234'
            get('/mounted/again/andagain').body.should eq '1234'
          end
        end

        context 'with different middleware or args' do
          before do
            app3.use middleware, 5
            base.use middleware, 5
          end

          it 'is used in mounted endpoints' do
            get('/mounted/again').body.should eq '12345'
            get('/mounted/again/andagain').body.should eq '12345'
          end
        end
      end
    end
  end

  describe '.basic_auth' do
    app do
      namespace :admin do
        basic_auth { |user, pass| user == 'admin' && pass == 'secret' }
        get { head }

        namespace :super_admin do
          basic_auth { |user, pass| user == 'super' && pass == 'secreter' }
          get { head }
        end
      end
    end

    it 'denies access' do
      get('/admin').status.should eq 401
    end

    it 'accepts valid credentials' do
      get('/admin', {}, auth('admin', 'secret')).should be_ok
    end

    it 'accepts nested credentials' do
      get('/admin/super_admin', {}, auth('super', 'secreter')).should be_ok
    end

    def auth user, pass
      { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64 "#{user}:#{pass}"}" }
    end
  end
end
