# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'travis/rollout/version'

Gem::Specification.new do |s|
  s.name          = 'travis-rollout'
  s.version       = Travis::Rollout::VERSION
  s.licenses      = ['MIT']
  s.authors       = ['Travis CI']
  s.email         = 'contact@travis-ci.org'
  s.homepage      = 'https://github.com/travis-ci/travis-rollout'
  s.summary       = 'Small helper class for rolling out apps'
  s.description   = "#{s.summary}."

  s.files         = Dir['{lib/**/*,spec/**/*,[A-Z]*}']
  s.platform      = Gem::Platform::RUBY
  s.require_paths = ['lib']
end
