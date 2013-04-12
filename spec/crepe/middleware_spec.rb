require 'spec_helper'

describe Crepe::API, "middleware" do
  app do
    use Rack::Runtime
    get

    scope :api do
      get
    end
  end

  it "runs in the stack" do
    get('/').headers.should include 'X-Runtime'
    get('/api').headers.should include 'X-Runtime'
  end

  describe "nesting" do
    context "with a namespace" do
      app do
        scope :api do
          use Rack::Runtime
        end
      end

      it "raises an exception" do
        expect { app }.to raise_error ArgumentError
      end
    end

    context "with a mount" do
      app do
        scope :api do
          runtime = Class.new Crepe::API do
            use Rack::Runtime
            get
          end
          mount runtime
        end

        get
      end

      it "uses middleware within mount namespace" do
        get('/api').headers.should include 'X-Runtime'
      end

      it "doesn't use middleware outside mount namespace" do
        get('/').headers.should_not include 'X-Runtime'
      end

      context "with duplicate middleware" do
        let(:app)    { Class.new(base, &routes) }
        let(:base)   { Class.new(Crepe::API, &routes) }
        let(:routes) { Proc.new { get { head } } }

        let(:middleware) do
          Class.new do
            def initialize app, *args, &block
              @app, @args, @block = app, args, block || ->(){}
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
    end
  end
end
