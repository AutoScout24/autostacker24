require 'bundler'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rake/clean'

CLEAN.include('pkg/**/*')

RSpec::Core::RakeTask.new(:spec)

Bundler::GemHelper.install_tasks

task :default => [:build]

