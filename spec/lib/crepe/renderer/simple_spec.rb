require 'spec_helper'
require_relative '../../../../lib/crepe/renderer/simple'

describe Crepe::Renderer::Simple do

  let(:endpoint) do
    Crepe::Endpoint.new{}.tap do |ep|
      allow(ep).to receive(:request) do
        Crepe::Request.new(Rack::MockRequest.env_for)
      end
    end
  end
  let(:renderer) { described_class.new(endpoint) }
  subject(:render) { renderer.render resource, format }

  it "renders string from simple hashes" do
    resource = { test: 1234 }
    expect(renderer.render resource, format: :text).to eq '{:test=>1234}'
  end

  it "renders json from simple hashes" do
    resource = { test: 1234 }
    expect(renderer.render resource, format: :json).to eq '{"test":1234}'
  end

  it "renders json from objects responding to #as_json" do
    resource = Struct.new(:as_json).new test: 1234
    expect(renderer.render resource, format: :json).to eq '{"test":1234}'
  end

end
