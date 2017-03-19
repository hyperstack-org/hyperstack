require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default do
  sh 'DRIVER=ff bundle exec rspec spec/batch1'
  sh 'DRIVER=ff bundle exec rspec spec/batch2'
  sh 'DRIVER=ff bundle exec rspec spec/batch3-from-reactive-record'
end
