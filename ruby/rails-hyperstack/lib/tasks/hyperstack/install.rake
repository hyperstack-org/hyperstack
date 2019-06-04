# install_template_path = File.expand_path("../../install/template.rb", __dir__).freeze
bin_path = ENV["BUNDLE_BIN"] || "./bin"
require 'optparse'

namespace :hyperstack do
  desc "Install Hyperstack in this application"
  task :install do
    exec "#{RbConfig.ruby} #{bin_path}/rails g hyperstack:install"
  end
  namespace :install do
    task :default do
    end
    task "hotloader-only" do
      exec "#{RbConfig.ruby} #{bin_path}/rails g hyperstack:install --hotloader-only"
    end
    task "webpack" do
      exec "#{RbConfig.ruby} #{bin_path}/rails g hyperstack:install --webpack-only"
    end
    task "hyper-model" do
      exec "#{RbConfig.ruby} #{bin_path}/rails g hyperstack:install --hyper-model-only"
    end
    task "skip-hotloader" do
      exec "#{RbConfig.ruby} #{bin_path}/rails g hyperstack:install --skip-hotloader"
    end
    task "skip-webpack" do
      exec "#{RbConfig.ruby} #{bin_path}/rails g hyperstack:install --skip-webpack"
    end
    task "skip-hyper-model" do
      exec "#{RbConfig.ruby} #{bin_path}/rails g hyperstack:install --skip-hyper-model"
    end
  end
end
