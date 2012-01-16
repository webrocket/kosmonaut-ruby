# -*- ruby -*-
require 'rubygems'

Gem::Specification.new do |s|
  s.name = "kosmonaut"
  s.version = "0.1.6"
  s.summary = "Ruby wrapper for kosmonaut"
  s.description = "Wrapper for the WebRocket client - Kosmonaut"
  s.authors = ["Krzysztof Kowalik", "Cubox"]
  s.email = "chris@nu7hat.ch"
  s.homepage = "http://webrocket.io/"
  s.license = "MIT"

  s.files = Dir["{{lib,ext/kosmonaut_ext,ext/include,test}/**/*.{rb,c,cpp,h,hpp},Rakefile,README*,COPYING,*.gemspec}"]
  s.test_files = Dir["test/*.rb"]
  s.require_paths = ["lib", "ext"]

  s.add_dependency "json", "~> 1.0"
end
