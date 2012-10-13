require 'spec_helper'
require_relative '../../../../lib/crepe/middleware/head'

describe Crepe::Middleware::Head do
  describes_middleware

  context 'a HEAD request' do
    before { head '/' }

    it 'sends as a GET request' do
      last_request.should be_get
    end

    it 'returns no content' do
      last_response.body.should be_empty
    end
  end

  %w[GET POST PUT PATCH DELETE].each do |method|
    context "a #{method} request" do
      before { send method.downcase, '/' }

      it "sends as a #{method} request" do
        last_request.request_method.should eq method
      end

      it 'returns content' do
        last_response.body.should_not be_empty
      end
    end
  end

end
