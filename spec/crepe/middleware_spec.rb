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
        app do
          middleware = Struct.new :app, :header do
            def call env
              status, headers, body = app.call env
              name = header || 'X-Count'
              headers[name] = (headers[name] || '0').next
              [status, headers, body]
            end
          end

          use middleware
          scope :first do
            inner = Class.new Crepe::API do
              use middleware
              get
            end
            mount inner
          end

          scope :second do
            inner = Class.new Crepe::API do
              use middleware, 'X-Count-2'
              get
            end
            mount inner
          end

          get
        end

        it "only mounts one copy" do
          get('/').headers['X-Count'].should eq '1'
          get('/first').headers['X-Count'].should eq '1'
          get('/second').headers['X-Count'].should eq '1'
          last_response.headers['X-Count-2'].should eq '1'
        end
      end
    end
  end
end
