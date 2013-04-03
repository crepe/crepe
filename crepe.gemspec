$LOAD_PATH.unshift File.expand_path 'lib', __dir__
require 'crepe/version'

Gem::Specification.new do |s|
  s.name        = 'crepe'
  s.version     = Crepe::VERSION
  s.summary     = 'Rack-based API framework'
  s.description = 'Rack-based API framework'

  s.files       = Dir['lib/**/*']

  s.has_rdoc    = false

  s.authors     = ['Stephen Celis', 'Evan Owen']
  s.email       = %w[stephen@stephencelis.com kainosnoema@gmail.com]
  s.homepage    = 'https://github.com/stephencelis/crepe'

  s.add_dependency 'activesupport', '~> 3.2.x'
  s.add_dependency 'rack',          '~> 1.5.x'
  s.add_dependency 'rack-mount',    '~> 0.8.x'

  s.add_development_dependency 'cane',       '~> 2.3.x'
  s.add_development_dependency 'multi_json', '~> 1.6.x'
  s.add_development_dependency 'multi_xml',  '~> 0.5.x'
  s.add_development_dependency 'rake',       '~> 10.0.x'
  s.add_development_dependency 'rspec',      '~> 2.13.x'
  s.add_development_dependency 'rack-test',  '~> 0.6.x'
  s.add_development_dependency 'tilt',       '~> 1.3.x'
end
