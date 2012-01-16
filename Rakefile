# -*- ruby -*-

=begin
require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Kosmonaut - The WebRocket backend client"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
=end

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end

task :default => :test

desc "Opens console with loaded mustang env."
task :console do
  $LOAD_PATH.unshift("./lib")
  require 'kosmonaut'
  require 'irb'
  ARGV.clear
  IRB.start
end
