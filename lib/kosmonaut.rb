require 'kosmonaut/errors'
require 'kosmonaut/socket'
require 'kosmonaut/worker'
require 'kosmonaut/client'
require 'kosmonaut/version'

module Kosmonaut
  extend self
  
  # Public: The debug mode switch. If true, then debug messages will
  # be printed out. 
  attr_accessor :debug

  # Internal: Simple logging method used to display debug information
  #
  # msg - The debug message to be displayed
  #
  def log(msg)
    print("DEBUG: ", msg, "\n") if Kosmonaut.debug
  end
end

Kosmonaut.debug = false
