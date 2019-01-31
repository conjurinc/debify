# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'conjur/debify/version'

Gem::Specification.new do |spec|
  spec.name          = "conjur-debify"
  spec.version       = Conjur::Debify::VERSION
  spec.authors       = ["Kevin Gilpin"]
  spec.email         = ["kgilpin@conjur.net"]
  spec.summary       = %q{Utility commands to build and package Conjur services as Debian packages}
  spec.homepage      = "https://github.com/conjurinc/debify"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  
  spec.add_dependency "gli"
  spec.add_dependency "docker-api", "~> 1.33"
  spec.add_dependency "conjur-cli" , "~> 6"
  spec.add_dependency "conjur-api", "~> 5"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "fakefs", "~> 0"
  spec.add_development_dependency "rake", "~> 10.0"
  
  # Pin to cucumbe v2. cucumber v3 changes (breaks) the behavior of
  # unmatched capture groups with \(d+). In v3, the value of such a
  # group is 0 instead of nil, which breaks aruba's "I successfully
  # run...." steps.
  spec.add_development_dependency "cucumber", '~> 2'
  spec.add_development_dependency "aruba"
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'ci_reporter_rspec', '~> 1.0'
end
