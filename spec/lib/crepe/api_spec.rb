require 'spec_helper'
require 'crepe'

describe Crepe::API do

  describe '.namespace' do
    app { namespace(:namespaced) { get { head } } }
    it 'wraps endpoints with prefix' do
      get('/namespaced').should be_ok
    end
  end

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

      context 'that mounts another app that mounts another and so on' do
        let(:app3) { Class.new base, &routes }

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

  describe '.helper' do
    context 'with a block' do
      app do
        helper { def helper_method() 'block' end }
        get { helper_method }
      end
      it 'extends endpoints with block methods' do
        get('/').body.should include 'block'
      end
    end

    context 'with a module' do
      app do
        helper(Module.new { def helper_method() 'module' end })
        get { helper_method }
      end
      it 'extends endpoints with module methods' do
        get('/').body.should include 'module'
      end
    end

    context 'defined after routes' do
      app do
        get { helper_method }
        helper { def helper_method() 'later' end }
      end
      it 'extends previously-defined endpoints' do
        get('/').body.should include 'later'
      end
    end

    context 'nested' do
      app do
        namespace :nest do
          get { { outer => inner } }
          helper { def inner() 'inner' end }
        end
        helper { def outer() 'outer' end }
      end
      it 'extends nested endpoints with outer helpers' do
        get('/nest').body.should eq '{"outer":"inner"}'
      end
    end
  end

end
