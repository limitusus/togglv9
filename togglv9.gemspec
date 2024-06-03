# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'togglv9/version'

Gem::Specification.new do |spec|
  spec.name          = "togglv9"
  spec.version       = TogglV9::VERSION
  spec.authors       = ["Tomoya Kabe"]
  spec.email         = ["limit.usus@gmail.com"]
  spec.summary       = %q{Toggl v9 API wrapper (See https://engineering.toggl.com/docs/), originally from kanet77/togglv8}
  spec.homepage      = "https://github.com/limitusus/togglv9"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.requirements  << 'A Toggl account (https://toggl.com/)'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency 'github_changelog_generator'
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-mocks"
  spec.add_development_dependency "coveralls_reborn"
  spec.add_development_dependency "pry"
  spec.add_development_dependency 'pry-byebug'
  # spec.add_development_dependency "awesome_print"

  spec.add_dependency "logger"
  spec.add_dependency "faraday", '>= 2.0.0'
  spec.add_dependency "oj"
end
