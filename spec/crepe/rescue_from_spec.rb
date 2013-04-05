require 'spec_helper'

describe Crepe::API, ".rescue_from" do
  app do
    rescue_from(StandardError) { head }
    rescue_from RuntimeError do |e|
      error! :bad_request, e.message
    end

    get do
      raise 'Time to run!'
    end

    namespace :errors do
      rescue_from ArgumentError, with: :error_handler
      rescue_from StandardError, with: :error_handler_with_argument

      get :argument do
        raise ArgumentError
      end

      get :standard do
        raise StandardError, 'Nothing to see here, folks.'
      end

      get :runtime do
        raise 'Run away! Run away!'
      end

      helper do
        def error_handler
          error! :unprocessable_entity
        end

        def error_handler_with_argument e
          error! :forbidden, e.message
        end
      end
    end
  end

  it "rescues with a block" do
    get '/'
    last_response.should be_bad_request
    last_response.body.should include 'Time to run!'
  end

  it "rescues with a handler without an argument" do
    get '/errors/argument'
    last_response.status.should eq 422
    last_response.body.should include 'Unprocessable Entity'
  end

  it "rescues with a handler with an argument" do
    get '/errors/standard'
    last_response.should be_forbidden
    last_response.body.should include 'Nothing to see here, folks.'
  end

  it "rescues with the most specific exception available" do
    get '/errors/runtime'
    last_response.should be_bad_request
    last_response.body.should include 'Run away! Run away!'
  end
end
