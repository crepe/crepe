require 'crepe'

# Parses input and echoes back the Ruby interpretation.
#
#   $ curl -d 'hello=world' 0.0.0.0:9292/parse
#   {"hello"=>"world"}
#   $ curl -H 'Content-Type: application/json' \
#          -d '{"hello":"world"}' 0.0.0.0:9292/parse
#   {"hello"=>"world"}
class RequestBodyParsing < Crepe::API
  respond_to :txt

  post 'parse' do
    request.body.inspect
  end
end

run RequestBodyParsing
