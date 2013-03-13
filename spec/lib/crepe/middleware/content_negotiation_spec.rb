require 'spec_helper'
require_relative '../../../../lib/crepe/middleware/content_negotiation'

describe Crepe::Middleware::ContentNegotiation do
  describes_middleware

  let(:core) {
    -> env {
      headers['Content-Type'] = env['HTTP_ACCEPT']
      headers['Location']     = env['PATH_INFO']
      headers['Vendor']       = env['crepe.vendor']

      [status, headers, body]
    }
  }

  context 'an accept header' do
    it 'sets vendor' do
      get '/test', {}, 'HTTP_ACCEPT' => 'application/vnd.acme'
      last_response.headers['Vendor'].should eq 'acme'
    end

    it 'negotiates version' do
      %w[v1 v2].each do |version|
        get '/test', {}, 'HTTP_ACCEPT' => "application/vnd.acme-#{version}"
        last_response.headers['Location'].should eq "/#{version}/test"
      end
    end

    it 'negotiates vendor format' do
      %w[json xml].each do |format|
        get '/test', {}, 'HTTP_ACCEPT' => "application/vnd.acme+#{format}"
        last_response.headers['Content-Type'].should eq(
          "application/#{format}"
        )
        last_response.headers['Location'].should eq "/test.#{format}"
      end
    end

    it 'negotiates version and format' do
      get '/test', {}, 'HTTP_ACCEPT' => "application/vnd.acme-v3+json"
      last_response.headers['Content-Type'].should eq 'application/json'
      last_response.headers['Location'].should eq '/v3/test.json'
    end

    it 'negotiates regular format' do
      %w[json xml].each do |format|
        get '/test', {}, 'HTTP_ACCEPT' => "application/#{format}"
        last_response.headers['Location'].should eq "/test.#{format}"
      end
    end

    it "doesn't clobber version prefixes" do
      get '/v3/test', {}, 'HTTP_ACCEPT' => 'application/vnd.acme-v3'
      last_response.headers['Location'].should eq '/v3/test'
    end

    it "doesn't clobber format extensions" do
      get '/test.json', {}, 'HTTP_ACCEPT' => 'application/vnd.acme+json'
      last_response.headers['Location'].should eq '/test.json'
    end

    it "doesn't clobber media parameters" do
      get '/test', {},
        'HTTP_ACCEPT' => "application/vnd.acme+json; charset=utf-8"
      last_response.headers['Content-Type'].should eq(
        'application/json; charset=utf-8'
      )
    end
  end

  context 'a query string' do
    it 'negotiates version' do
      get '/test?v=v3'
      last_response.headers['Location'].should eq '/v3/test'
    end

    it 'removes parameter v' do
      get '/test?v=v3'
      last_request.env['QUERY_STRING'].should be_empty
    end

    it 'preserves other parameters' do
      get '/test?v=v3&q=search'
      last_request.env['QUERY_STRING'].should eq 'q=search'
    end
  end
end
