require 'crepe'
require 'json'

# Accessible only via basic auth:
#
#   $ curl admin:password@0.0.0.0:9292/admin.json
class BasicAuth < Crepe::API
  basic_auth do |username, password|
    username == 'admin' && password == 'password'
  end

  get '/admin' do
    { message: 'Hello, world!' }
  end
end

run BasicAuth
