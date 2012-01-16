require 'rbconfig'
require 'mkmf'

have_library('pthread')
have_library('uuid', 'uuid_generate')
have_header('uuid/uuid.h')
have_header('string.h')

ext_dir = File.expand_path("..", __FILE__)
$CFLAGS << " -I#{ext_dir}"
include_dir = File.expand_path("../../include", __FILE__)
$CFLAGS << " -I#{include_dir}"

create_makefile('kosmonaut_ext')
