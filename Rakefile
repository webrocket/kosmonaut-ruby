# -*- ruby -*-
begin
  require 'rake/extensiontask'
  Rake::ExtensionTask.new("kosmonaut_ext") do |ext|
    ext.lib_dir = 'lib'
    ext.source_pattern = "**/*.{c,cpp}"
  end
rescue LoadError
  STDERR.puts "Run `gem install rake-compiler` to install 'rake-compiler'."
end

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Kosmonaut - The WebRocket backend client"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end

ROOT = File.dirname(__FILE__)
SRC_DIR = "#{ROOT}/ext/kosmonaut"
EXT_DIR = "#{ROOT}/ext/kosmonaut_ext"
INC_DIR = "#{ROOT}/ext/include"

task :prepare_ext do
  system("mkdir -p #{EXT_DIR}")
  system("mkdir -p #{INC_DIR}")
  system("cp #{SRC_DIR}/*.{c,h} #{EXT_DIR}")
  system("cp #{SRC_DIR}/extconf.rb #{EXT_DIR}")
  %w{zmq czmq kosmonaut}.each { |lib|
    system("cp -R #{SRC_DIR}/lib#{lib}/src/* #{EXT_DIR}")
    system("cp -R #{SRC_DIR}/lib#{lib}/include/* #{INC_DIR}")
  }
end

task :cleanup_ext do
  system("rm -rf #{EXT_DIR} #{INC_DIR}")
end

task :build => [:prepare_ext] do
  system("gem build kosmonaut.gemspec")
end

Rake::Task[:clean].prerequisites.unshift(:cleanup_ext)
Rake::Task[:compile].prerequisites.unshift(:prepare_ext)

task :clean_and_compile => [:clean, :compile]
Rake::Task[:test].prerequisites.unshift(:clean_and_compile)

task :default => :test

desc "Opens console with loaded mustang env."
task :console do
  $LOAD_PATH.unshift("./lib")
  require 'kosmonaut'
  require 'irb'
  ARGV.clear
  IRB.start
end
