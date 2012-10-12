require 'spec_helper'
require_relative '../../../../lib/crepe/middleware/content_negotiation'

describe Crepe::Middleware::ContentNegotiation do
  describes_middleware

  let(:core) {
    ->(env) {
      headers['Content-Type'] = env['HTTP_ACCEPT']
      headers['Location']     = env['PATH_INFO']
      headers['Vendor']       = env['crepe.vendor']

      [status, headers, body]
    }
  }

  it 'negotiates version and format' do
    get '/test', {}, 'HTTP_ACCEPT' => 'application/vnd.acme-v3+json'

    last_response.headers['Content-Type'].should eq 'application/json'
    last_response.headers['Location'].should eq '/v3/test.json'
    last_response.headers['Vendor'].should eq 'acme'
  end

  it 'negotiates version and format' do
    get '/test', {},
      'HTTP_ACCEPT' => 'application/vnd.acme-v3+xml; charset=utf-8'

    last_response.headers['Content-Type'].should eq(
      'application/xml; charset=utf-8'
    )
    last_response.headers['Location'].should eq '/v3/test.xml'
    last_response.headers['Vendor'].should eq 'acme'
  end
end
