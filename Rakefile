require "bundler/gem_tasks"
require "rspec/core/rake_task"



task :spec do
  (1..7).each { |batch| Rake::Task["spec:batch#{batch}"].invoke rescue nil }
end

namespace :spec do
  task :prepare do
    sh %{bundle update}
    sh %{cd spec/test_app; bundle update; bundle exec rails db:setup} # may need ;bundle exec rails db:setup as well
  end
  (1..7).each do |batch|
    RSpec::Core::RakeTask.new(:"batch#{batch}") do |t|
      t.pattern = "spec/batch#{batch}/**/*_spec.rb"
    end
  end
end

task :default => :spec
