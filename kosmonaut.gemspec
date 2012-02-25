# -*- ruby -*-
require 'rubygems'
require File.expand_path("../lib/kosmonaut/version", __FILE__)

Gem::Specification.new do |s|
  s.name = "kosmonaut"
  s.version = Kosmonaut.version
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
  s.add_dependency "activesupport", ">= 3.0"
  s.add_development_dependency "minitest", "~> 2.0"
end
