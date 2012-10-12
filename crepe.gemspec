$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'crepe/version'

Gem::Specification.new do |s|
  s.name        = 'crepe'
  s.version     = Crepe::VERSION
  s.summary     = 'Rack-based API framework'
  s.description = <<EOF
Rack-based API framework
EOF

  s.files       = Dir['lib/**/*']

  s.has_rdoc    = false

  s.authors     = ['Stephen Celis', 'Evan Owen']
  s.email       = %w[stephen@stephencelis.com kainosnoema@gmail.com]
  s.homepage    = 'https://github.com/stephencelis/crepe'

  s.add_dependency 'activesupport', '~> 3.2'
  s.add_dependency 'rack',          '~> 1.4'
  s.add_dependency 'rack-mount',    '~> 0.8'

  s.add_development_dependency 'cane',       '~> 2.3'
  s.add_development_dependency 'multi_json', '~> 1.3'
  s.add_development_dependency 'multi_xml',  '~> 0.5'
  s.add_development_dependency 'rake',       '~> 0.9'
  s.add_development_dependency 'rspec',      '~> 2.11'
  s.add_development_dependency 'rack-test',  '~> 0.6.2'
  s.add_development_dependency 'tilt',       '~> 1.3'
end
