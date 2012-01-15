# -*- ruby -*-
begin
  require 'rake/extensiontask'
  Rake::ExtensionTask.new("kosmonaut") do |ext|
    ext.lib_dir = 'lib/kosmonaut/c'
    ext.source_pattern = "*.{c,h}"
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

task :test => [:clean, :compile]
task :default => :test

desc "Opens console with loaded mustang env."
task :console do
  $LOAD_PATH.unshift("./lib")
  require 'kosmonaut'
  require 'irb'
  ARGV.clear
  IRB.start
end
