require 'rubygems'
require 'hotcocoa/application_builder'
require 'hotcocoa/standard_rake_tasks'

task :default => [:run]

task :embed => [:clean, :build] do
  `macruby_deploy --no-stdlib --embed "#{AppConfig.name}.app"`
end