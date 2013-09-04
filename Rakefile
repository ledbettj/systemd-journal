require "bundler/gem_tasks"
require "yard"
require "rspec/core/rake_task"

desc "open a console with systemd/journal required"
task :console do
  exec 'pry -I./lib -r systemd/journal'
end

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
  t.options = ['--no-private', '--markup=markdown']
end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "--color"
end

task default: :spec
