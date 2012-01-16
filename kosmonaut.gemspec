# -*- ruby -*-
require 'rubygems'

Gem::Specification.new do |s|
  s.name = "kosmonaut"
  s.version = "0.2.0"
  s.summary = "Ruby client for the WebRocket backend"
  s.description = "The WebRocket server backend client for ruby programming language"
  s.authors = ["Krzysztof Kowalik", "Cubox"]
  s.email = "chris@nu7hat.ch"
  s.homepage = "http://webrocket.io/"
  s.license = "MIT"

  s.files = Dir["{lib/**/*.rb,test/*.rb,Rakefile,README,COPYING,NEWS,ChangeLog,*.gemspec}"]
  s.test_files = Dir["test/*.rb"]
  s.require_paths = ["lib"]

  s.add_dependency "json", "~> 1.0"
  s.add_development_dependency "minitest", "~> 2.0"
end
