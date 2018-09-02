require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

namespace :spec do
  task :prepare do
    sh %{bundle update}
    sh %{cd spec/test_app; bundle update} # may need ;bundle exec rails db:setup as well
  end
end

task :default => :spec
