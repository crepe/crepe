require 'spec_helper'

describe Crepe::API, "middleware" do
  middleware = Class.new do
    def initialize app, *args, &block
      @app, @args, @block = app, args, block || ->{}
    end

    def call env
      _, hdr, _ = *@app.call(env)
      hdr['X-Count'] = (hdr['X-Count'] || 0) + 1
      [200, hdr, [*@args, *@block.call].map(&:to_s)]
    end
  end

  app do
    use middleware; get
    scope(:api) { get }
  end

  it "runs in the stack" do
    get('/').headers.should include 'X-Count'
    get('/api').headers.should include 'X-Count'
  end

  describe "arguments" do
    app do
      use(middleware, 1, 2) { 3 }; get
    end

    it "accepts arguments and block" do
      get('/').body.should eq '123'
    end
  end

  describe "inheritance" do
    base = api { use middleware }
    let(:app) { api(base) { get } }

    it "uses middleware from the superclass" do
      get('/').headers.should include 'X-Count'
    end
  end

  describe "nesting" do
    context "with a namespace" do
      app { scope(:api) { use middleware } }

      it "raises an exception" do
        expect { app }.to raise_error ArgumentError
      end
    end

    context "with a mount" do
      app do
        api1 = api { use middleware; get }
        scope(:api1) { mount api1 }
        get
      end

      it "uses middleware within mount namespace" do
        get('/api1').headers.should include 'X-Count'
      end

      it "doesn't use middleware outside mount namespace" do
        get('/').headers.should_not include 'X-Count'
      end

      context "with duplicate middleware" do
        context "with the same arguments" do
          app do
            api3 = api { use middleware; scope(:api3) { get } }
            api2 = api { use middleware; scope(:api2) { get; mount api3 } }
            mount  api { use middleware; scope(:api1) { get; mount api2 } }
          end

          it "is not used again" do
            get('/api1/api2/api3').headers['X-Count'].should eq 1
          end
        end

        context "with different arguments" do
          app do
            api3 = api { use middleware, 3; scope(:api3) { get } }
            api2 = api { use middleware, 2; scope(:api2) { get; mount api3 } }
            mount  api { use middleware, 1; scope(:api1) { get; mount api2 } }
          end

          it "is used in mounted endpoints" do
            get('/api1/api2/api3').headers['X-Count'].should eq 3
          end
        end

      end
    end
  end
end
