require 'rbconfig'
require 'mkmf'

have_library('pthread')
have_library('uuid', 'uuid_generate')
have_header('uuid/uuid.h')
have_header('string.h')

dir = File.expand_path("../..", __FILE__)

$CFLAGS << " -I#{dir}/zeromq/include -I#{dir}/zeromq/src"
$CFLAGS << " -I#{dir}/czmq/include -I#{dir}/czmq/src"
$CFLAGS << " -I#{dir}/kosmonaut/include -I#{dir}/kosmonaut/src"

create_makefile('zeromq')
