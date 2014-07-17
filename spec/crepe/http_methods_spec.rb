require 'spec_helper'

class HelloWorld
  def self.call(env)
    body = ["Hello, #{env['REQUEST_METHOD']}!"]
    [200, { 'Content-Type' => 'text/plain' }, body]
  end
end

describe Crepe::API, 'HTTP methods' do
  app do
    scope :method do
      respond_to :json, :html

      get    '/get'
      post   '/post'
      put    '/put'
      patch  '/patch'
      delete '/delete'
      any    '/any'
    end

    scope :hello do
      get    HelloWorld
      post   HelloWorld
      put    HelloWorld
      delete HelloWorld

      get    :world, to: HelloWorld
      post   :world, to: HelloWorld
      put    :world, to: HelloWorld
      delete :world, to: HelloWorld
    end
  end

  methods = Crepe::API::METHODS.map(&:downcase)
  methods.each do |method|
    describe ".#{method}" do
      it "routes #{method.upcase} requests" do
        expect(send method, "/method/#{method}").to be_successful
      end

      if method == 'get'
        it "routes HEAD requests" do
          expect(head "/method/#{method}").to be_successful
        end
      else
        it "does not route HEAD requests" do
          expect(head "/method/#{method}").to be_method_not_allowed
        end
      end

      it "routes OPTIONS requests" do
        expect(options "/method/#{method}").to be_successful
      end

      it "routes OPTIONS requests other formats" do
        expect(options "/method/#{method}.html").to be_successful
      end

      it "does not route anything else" do
        (methods - [method]).each do |other_method|
          send(other_method, "/method/#{method}")
          expect(last_response).to be_method_not_allowed
        end
      end

      if method == 'patch'
        it "does not route a Rack application if the method is not allowed" do
          send method, '/hello'
          expect(last_response).to be_method_not_allowed
        end
      else
        it "directly routes to a Rack application" do
          send method, '/hello'
          expect(last_response).to be_successful
          expect(last_response.body).to eq("Hello, #{method.upcase}!")
        end

        it "routes to a Rack application using the :to option" do
          send method, '/hello/world'
          expect(last_response).to be_successful
          expect(last_response.body).to eq("Hello, #{method.upcase}!")
        end
      end
    end
  end

  describe ".any" do
    it "routes anything" do
      (methods + %w[head options]).each do |method|
        expect(send method, '/method/any').to be_successful
      end
    end
  end
end
