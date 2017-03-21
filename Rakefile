require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default do
  sh 'DRIVER=pg bundle exec rspec spec/batch1 -f d'
  sh 'DRIVER=pg bundle exec rspec spec/batch2 -f d'
  sh 'DRIVER=pg bundle exec rspec spec/batch3 -f d'
  sh 'DRIVER=pg bundle exec rspec spec/batch4 -f d'
end
