# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lifx/version'

Gem::Specification.new do |spec|
  spec.name          = "lifx"
  spec.version       = LIFX::VERSION
  spec.authors       = ["Jack Chen (chendo)"]
  spec.email         = ["chendo@lifx.co"]
  spec.description   = %q{A Ruby gem that allows easy interaction with LIFX devices.}
  spec.summary       = %q{A Ruby gem that allows easy interaction with LIFX devices. Handles discovery, rate limiting, tags, gateway connections and provides an object-based API for interacting with LIFX devices. }
  spec.homepage      = "https://github.com/LIFX/lifx-gem"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/).reject { |f| f =~ /^script\// }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.1"

  spec.add_dependency "bindata", "~> 2.0"
  spec.add_dependency "yell", "~> 2.0"
  spec.add_dependency "timers", "~> 1.0"
  spec.add_dependency "configatron", "~> 3.0"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 10.1"
  spec.add_development_dependency "rspec", "~> 2.14"
end
