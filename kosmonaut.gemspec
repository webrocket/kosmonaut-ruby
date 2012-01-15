# -*- ruby -*-
require 'rubygems'

Gem::Specification.new do |s|
  s.name = "kosmonaut"
  s.version = "0.1.0"
  s.summary = "Ruby wrapper for kosmonaut"
  s.description = "Wrapper for the WebRocket client - Kosmonaut"
  s.authors = ["Krzysztof Kowalik", "Cubox"]
  s.email = "chris@nu7hat.ch"
  s.homepage = "http://webrocket.io/"
  s.platform = Gem::Platform::RUBY
  s.extensions = ["ext/kosmonaut/extconf.rb"]
  s.license = "MIT"

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files spec`.split("\n")
  s.require_paths = ["lib", "ext"]

  s.add_dependency "json", "~> 1.0"
  s.add_development_dependency "rake-compiler", "~> 0.7"
  s.add_development_dependency "gem-compile"
end
