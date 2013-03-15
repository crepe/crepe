require 'crepe'

# Demonstrates several versions:
#
#   $ curl -H 'Accept: application/vnd.crepe-v1+json' 0.0.0.0:9292
#   {"message":"Version 1"}
#   $ curl 0.0.0.0:9292/v2
#   {"message":"Version 2"}
class Versioning < Crepe::API
  version :v1 do
    get do
      { message: 'Version 1' }
    end
  end

  version :v2 do
    get do
      { message: 'Version 2' }
    end
  end
end

run Versioning
