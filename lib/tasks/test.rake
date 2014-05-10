require 'rake/testtask'
Rake::TestTask.new do |t|
  t.pattern = "#{File.join(File.dirname(File.realpath(__FILE__)), '../../spec')}/*_spec.rb"
end

task :t => :test
