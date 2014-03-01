# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lifx/version'

Gem::Specification.new do |spec|
  spec.name          = "lifx"
  spec.version       = LIFX::VERSION
  spec.authors       = ["Jack Chen (chendo)"]
  spec.email         = ["chendo@lifx.co"]
  spec.description   = %q{Ruby client for LIFX}
  spec.summary       = %q{Ruby client for LIFX}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/).reject { |f| f =~ /^script\// }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'bindata'
  spec.add_dependency 'yell'
  spec.add_dependency 'timers'
  spec.add_dependency 'configatron', '~> 3.0'
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "erubis"
  spec.add_development_dependency "ruby-prof"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "pry-rescue"
  spec.add_development_dependency "pry-stack_explorer"
end
