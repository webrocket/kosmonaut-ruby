# -*- ruby -*-
require 'rubygems'

Gem::Specification.new do |s|
  s.name = "webrocket"
  s.version = "0.1.0"
  s.summary = "Ruby wrapper for kosmonaut"
  s.description = "Wrapper for the WebRocket client - kosmonaut"
  s.authors = ["Krzysztof Kowalik"]
  s.email = "chris@nu7hat.ch"
  s.platform = Gem::Platform::RUBY
  s.extensions = FileList["ext/**/extconf.rb"]
end
