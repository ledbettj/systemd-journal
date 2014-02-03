require 'bundler/gem_tasks'
require 'yard'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

desc 'open a console with systemd/journal required'
task :console do
  exec 'pry -I./lib -r systemd/journal'
end

Rubocop::RakeTask.new(:rubocop) do |task|
  task.patterns = ['lib/**/*.rb', 'spec/**/*.rb']
  task.fail_on_error = false
end

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
  t.options = ['--no-private', '--markup=markdown']
end

RSpec::Core::RakeTask.new(:spec) do |t|
  opts = ['--color']
  opts << '--require ./spec/no_ffi.rb' if ENV['TRAVIS']
  t.rspec_opts = opts.join(' ')
end

task default: :spec
