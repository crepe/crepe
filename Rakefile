require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new :spec do |t|
  t.rspec_opts = ['--color', '--format progress', '--order rand']
end

task default: :spec
