defaults = []

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new :spec do |t|
    t.rspec_opts = ['--color', '--format progress', '--order rand']
  end
  defaults << :spec
rescue LoadError
  warn 'RSpec not available, spec task not provided.'
end

begin
  require 'cane/rake_task'
  Cane::RakeTask.new :quality
  defaults << :quality
rescue LoadError
  warn 'cane not available, quality task not provided.'
end

task default: defaults
