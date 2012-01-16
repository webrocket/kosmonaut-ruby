require 'kosmonaut/errors'
require 'kosmonaut/socket'
require 'kosmonaut/worker'
require 'kosmonaut/client'
require 'kosmonaut/version'

module Kosmonaut
  extend self
  attr_accessor :debug

  def log(msg)
    print("DEBUG: ", msg, "\n") if Kosmonaut.debug
  end
end

Kosmonaut.debug = false
