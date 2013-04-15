require 'crepe'
require 'multi_json'
require 'multi_xml'

# Parses input and echoes back the Ruby interpretation.
#
#   $ curl -d 'hello=world' 0.0.0.0:9292/parse
#   {"hello"=>"world"}
#   $ curl -H 'Content-Type: application/json' \
#          -d '{"hello":"world"}' 0.0.0.0:9292/parse
#   {"hello"=>"world"}
#   $ curl -H 'Content-Type: application/xml' \
#          -d '<hello>enterprise</hello>' 0.0.0.0:9292/parse
#   {"hello"=>"enterprise"}
class RequestBodyParsing < Crepe::API
  respond_to :txt

  post 'parse' do
    request.body.inspect
  end
end

run RequestBodyParsing
