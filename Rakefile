require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'rake/clean'
require 'rdoc/task'
require 'github_changelog_generator/task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

CLEAN.add 'coverage'
CLEAN.add 'doc'
CLEAN.add 'html'
CLEAN.include 'tmp-*'

GitHubChangelogGenerator::RakeTask.new :changelog do |config|
  config.user = 'limitusus'
  config.project = 'togglv9'
  config.since_tag = 'v0.1.0'
  config.future_release = '0.2.0'
end

RDoc::Task.new do |rdoc|
  rdoc.options += %w[--exclude vendor/bundle/**]
end
