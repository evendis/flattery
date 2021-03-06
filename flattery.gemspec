# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'flattery/version'

Gem::Specification.new do |spec|
  spec.name          = "flattery"
  spec.version       = Flattery::VERSION
  spec.authors       = ["Paul Gallagher"]
  spec.email         = ["paul@evendis.com"]
  spec.description   = %q{a gem to denormalize (flatten) selected ActiveRecord association attributes and automatically keep them in sync with the normal form}
  spec.summary       = %q{Flatter your nicely normalized ActiveRecord models}
  spec.homepage      = "https://github.com/evendis/flattery"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport", ">= 3.0.3"
  spec.add_runtime_dependency "activerecord", ">= 3.0.3"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rdoc"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "rb-fsevent"
  spec.add_development_dependency "sqlite3", ">= 1.3.2"

end
