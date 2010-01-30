require 'rubygems'
require 'hotcocoa/application_builder'
require 'hotcocoa/standard_rake_tasks'

task :default => [:run]

task :unpack do
  `macgem unpack hotcocoa` unless File.directory? "hotcocoa-0.5.1"
end

task :embed => [:clean, :unpack, :build] do
  `macruby_deploy --no-stdlib --embed "#{AppConfig.name}.app"`
end