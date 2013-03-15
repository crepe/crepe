require 'crepe'

# Basic authentication can be scoped easily. In this example, the root doesn't
# require it.
#
#   $ curl 0.0.0.0:9292
#   {"message":"Hello, world!"}
#
# The admin layer, on the other hand, does.
#
#   $ curl 0.0.0.0:9292/admin
#   {"error":{"message":"Unauthorized"}}
#   $ curl admin:password@0.0.0.0:9292/admin
#   {"message":"Hello, admin!"}
class BasicAuth < Crepe::API
  get do
    { message: 'Hello, world!' }
  end

  namespace :admin do
    basic_auth do |username, password|
      username == 'admin' && password == 'password'
    end

    get do
      { message: 'Hello, admin!' }
    end
  end
end

run BasicAuth
