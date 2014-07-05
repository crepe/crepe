require 'spec_helper'
require_relative '../../../../lib/crepe/middleware/head'

describe Crepe::Middleware::Head do
  describes_middleware

  context 'a HEAD request' do
    before { head '/' }

    it 'sends as a GET request' do
      expect(last_request).to be_get
    end

    it 'returns no content' do
      expect(last_response.body).to be_empty
    end
  end

  %w[GET POST PUT PATCH DELETE].each do |method|
    context "a #{method} request" do
      before { send method.downcase, '/' }

      it "sends as a #{method} request" do
        expect(last_request.request_method).to eq method
      end

      it 'returns content' do
        expect(last_response.body).not_to be_empty
      end
    end
  end

end
