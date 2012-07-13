require 'spec_helper'
require_relative '../../../../lib/cape/middleware/content_negotiation'

describe Cape::Middleware::ContentNegotiation do
  describes_middleware

  let(:core) {
    ->(env) {
      headers['Content-Type'] = env['HTTP_ACCEPT']
      headers['Location']     = env['PATH_INFO']
      headers['Vendor']       = env['cape.vendor']

      [status, headers, body]
    }
  }

  it 'negotiates version and format' do
    get '/test', {}, 'HTTP_ACCEPT' => 'application/vnd.recurly.v3+json'

    last_response.headers['Content-Type'].should eq('application/json')
    last_response.headers['Location'].should eq('/v3/test.json')
    last_response.headers['Vendor'].should eq('recurly')
  end
end
