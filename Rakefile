defaults = []

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new :spec do |t|
    t.rspec_opts = ['--color', '--format progress', '--order rand']
    t.ruby_opts = ['-W2']
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

task :loc do
  print '  lib   '
  puts `zsh -c "grep -vE '^ *#|^$' lib/**/*.rb | wc -l"`.strip
  print '  spec  '
  puts `zsh -c "grep -vE '^ *#|^$' spec/**/*.rb | wc -l"`.strip
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new :doc do |t|
    # t.options = ['--hide-void-return']
    t.files = %w[lib/**/*.rb]
  end
rescue LoadError
  warn 'YARD not available, doc task not provided.'
end
