require 'rubygems'
require 'hotcocoa/application/builder'

builder = Application::Builder.new 'Stopwatch.appspec'

desc 'Build the application'
task :build do
  builder.build
end

desc 'Build a deployable version of the application'
task :deploy do
  builder.build deploy: true
end

desc 'Build and execute the application'
task :run => [:build] do
  builder.run
end

desc 'Cleanup build files'
task :clean do
  builder.remove_bundle_root
end

task :default => [:run]
