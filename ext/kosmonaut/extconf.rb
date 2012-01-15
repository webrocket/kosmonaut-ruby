require 'rbconfig'
require 'mkmf'

def darwin?
  RUBY_PLATFORM =~ /darwin/
end

def compile_vendor_kosmonaut
  kosmonaut_dir = File.expand_path("../../vendor/kosmonaut", __FILE__)
  Dir.chdir(kosmonaut_dir) {
    system("make")
  }
end

have_library('pthread')
have_library('zmq')
have_library('czmq')
have_library('uuid', 'uuid_generate')
have_library('kosmonaut')

create_makefile('kosmonaut')
