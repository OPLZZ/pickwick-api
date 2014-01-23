# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pickwick/api/version'

Gem::Specification.new do |spec|
  spec.name          = "pickwick-api"
  spec.version       = Pickwick::API::VERSION
  spec.authors       = ["Vojtech Hyza"]
  spec.email         = ["vhyza@vhyza.eu"]
  spec.description   = %q{Main API for damepraci.eu project}
  spec.summary       = %q{Main API for damepraci.eu project}
  spec.homepage      = "http://damepraci.eu"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "sinatra"
  spec.add_dependency "puma"
  spec.add_dependency "rubykiq"
  spec.add_dependency "rdiscount"
  spec.add_dependency "virtus"
  spec.add_dependency "activemodel", "~> 4"
  spec.add_dependency "jbuilder"
  spec.add_dependency "oj"
  spec.add_dependency "ruby-duration"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_development_dependency "pry"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "shotgun"
  spec.add_development_dependency "shoulda-context"
  spec.add_development_dependency "turn"
  spec.add_development_dependency "factory_girl"
  spec.add_development_dependency "faker"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "simplecov"
end
