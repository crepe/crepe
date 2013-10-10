require 'spec_helper'
require_relative '../../../../lib/crepe/renderer/pagination'

describe Crepe::Renderer::Pagination::Links do

  let(:uri) { 'http://example.com/search' }
  let(:request) { Crepe::Request.new Rack::MockRequest.env_for uri }

  it "renders the first of multiple pages" do
    header = ['<http://example.com/search?page=2>; rel="next"',
              '<http://example.com/search?page=6>; rel="last"'].join(', ')

    links = described_class.new request, 1, 10, 55
    links.render.should == header
  end

  it "renders the second of multiple pages" do
    header = ['<http://example.com/search>; rel="first"',
              '<http://example.com/search>; rel="prev"',
              '<http://example.com/search?page=3>; rel="next"',
              '<http://example.com/search?page=6>; rel="last"'].join(', ')

    links = described_class.new request, 2, 10, 55
    links.render.should == header
  end

  it "renders the third of multiple pages" do
    header = ['<http://example.com/search>; rel="first"',
              '<http://example.com/search?page=2>; rel="prev"',
              '<http://example.com/search?page=4>; rel="next"',
              '<http://example.com/search?page=6>; rel="last"'].join(', ')

    links = described_class.new request, 3, 10, 55
    links.render.should == header
  end

  it "renders the last page" do
    header = ['<http://example.com/search>; rel="first"',
              '<http://example.com/search?page=5>; rel="prev"'].join(', ')

    links = described_class.new request, 6, 10, 55
    links.render.should == header
  end
end
