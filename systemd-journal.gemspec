# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'systemd/journal/version'

Gem::Specification.new do |gem|
  gem.name          = "systemd-journal"
  gem.version       = Systemd::Journal::VERSION
  gem.authors       = ["John Ledbetter"]
  gem.email         = ["john@throttle.io"]
  gem.description   = %q{systemd journal bindings for ruby}
  gem.summary       = %q{systemd journal bindings for ruby}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'ffi', '~>1.9.0'
end
