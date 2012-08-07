$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'cape/version'

Gem::Specification.new do |s|
  s.name        = 'cape'
  s.version     = Cape::VERSION
  s.summary     = 'Rack-based API framework'
  s.description = <<EOF
Rack-based API framework
EOF

  s.files       = Dir['lib/**/*']

  s.has_rdoc    = false

  s.authors     = ['Stephen Celis', 'Evan Owen']
  s.email       = %w[stephen@stephencelis.com kainosnoema@gmail.com]
  s.homepage    = 'https://github.com/stephencelis/cape'

  s.add_dependency 'activesupport', '~> 3.2.7'
  s.add_dependency 'rack',          '~> 1.4.1'

  s.add_development_dependency 'rspec'
end
