require "bundler/gem_tasks"
require "yard"

task :console do
  exec 'pry -I./lib -r systemd/journal'
end

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
  t.options = ['--no-private', '--markup=markdown']
end
