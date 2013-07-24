# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'systemd/journal/version'

Gem::Specification.new do |gem|
  gem.name          = "systemd-journal"
  gem.version       = Systemd::Journal::VERSION
  gem.authors       = ["John Ledbetter"]
  gem.email         = ["john@throttle.io"]
  gem.description   = %q{Provides the ability to navigate and read entries from the systemd journal in ruby.}
  gem.summary       = %q{Ruby bindings to libsystemd-journal}
  gem.homepage      = "https://github.com/ledbettj/systemd-journal"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'ffi', '~>1.9.0'
end
