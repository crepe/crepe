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
  s.homepage    = 'https://github.com/crepe/crepe'

  s.required_ruby_version = '>= 2.0.0'

  s.add_dependency 'activesupport', '>= 4.0.0'
  s.add_dependency 'rack',          '~> 1.5.x'
  s.add_dependency 'rack-mount',    '~> 0.8.x'

  s.add_development_dependency 'cane',      '~> 2.6.x'
  s.add_development_dependency 'rake',      '~> 10.3.x'
  s.add_development_dependency 'rspec',     '~> 3.0.x'
  s.add_development_dependency 'rack-test', '~> 0.6.x'
  s.add_development_dependency 'yard',      '~> 0.8.x'
end
