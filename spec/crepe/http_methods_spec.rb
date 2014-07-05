require 'spec_helper'

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
