require 'crepe'

# Demonstrates streaming.
#
# Use Puma to avoid blocking:
#
#   $ puma examples/stream.ru
#
# Stream:
#
#   $ curl 0.0.0.0:9292
#   {"timestamp":1363212643}
#   {"timestamp":1363212644}
#   {"timestamp":1363212645}
#   {"timestamp":1363212646}
#   {"timestamp":1363212647}
#   ^C
class Stream < Crepe::API
  stream do
    loop do
      render timestamp: Time.now.to_i
      sleep 1
    end
  end
end

run Stream
