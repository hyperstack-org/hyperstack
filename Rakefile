# require 'bundler'
# Bundler.require
# Bundler::GemHelper.install_tasks
#
# # Store the BUNDLE_GEMFILE env, since rake or rspec seems to clean it
# # while invoking task.
# ENV['REAL_BUNDLE_GEMFILE'] = ENV['BUNDLE_GEMFILE']
#
# require 'rspec/core/rake_task'
# require 'opal/rspec/rake_task'
#
# RSpec::Core::RakeTask.new('ruby:rspec')
#
# task :test do
#   Rake::Task['ruby:rspec'].invoke
# end
#
# require 'generators/reactive_ruby/test_app/test_app_generator'
# desc "Generates a dummy app for testing"
# task :test_app do
#   ReactiveRuby::TestAppGenerator.start
#   puts "Setting up test app database..."
#   system("bundle exec rake db:drop db:create db:migrate > #{File::NULL}")
# end
#
# task :test_prepare do
#   system("./dciy_prepare.sh")
# end
#
# task default: [ :test ]

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

namespace :spec do
  task :prepare do
    sh %{bundle update}
    sh %{cd spec/test_app; bundle update}
  end
end

task :default => :spec
