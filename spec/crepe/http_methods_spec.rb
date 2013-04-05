require 'spec_helper'

describe Crepe::API, 'HTTP methods' do
  app do
    get    '/get'
    post   '/post'
    put    '/put'
    patch  '/patch'
    delete '/delete'
    any    '/any'
  end

  methods = Crepe::API::METHODS.map(&:downcase)
  methods.each do |method|
    describe ".#{method}" do
      it "routes #{method.upcase} requests" do
        send(method, "/#{method}").should be_successful
      end

      if method == 'get'
        it "routes HEAD requests" do
          head("/#{method}").should be_successful
        end
      else
        it "does not route HEAD requests" do
          head("/#{method}").should be_method_not_allowed
        end
      end

      it "routes OPTIONS requests" do
        options("/#{method}").should be_successful
      end

      it "does not route anything else" do
        (methods - [method]).each do |other_method|
          send(other_method, "/#{method}").should be_method_not_allowed
        end
      end
    end
  end

  describe ".any" do
    it "routes anything" do
      (methods + %w[head options]).each do |method|
        send(method, '/any').should be_successful
      end
    end
  end
end
