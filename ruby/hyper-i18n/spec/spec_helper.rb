require 'pry'
require 'opal-browser'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../test_app/config/environment', __FILE__)

require 'rspec/rails'
require 'hyper-spec'
require 'hyper-i18n'

RSpec.configure do |config|

  config.before :suite do
    MiniRacer_Backup = MiniRacer
    Object.send(:remove_const, :MiniRacer)
  end

  config.around(:each, :prerendering_on) do |example|
    MiniRacer = MiniRacer_Backup
    example.run
    Object.send(:remove_const, :MiniRacer)
  end

  config.color = true
  config.formatter = :documentation
  config.before(:all) do
    `rm -rf spec/test_app/tmp/cache/`
  end

  # Use legacy hyper-spec on_client behavior
  HyperSpec::ComponentTestHelpers.alias_method :on_client, :before_mount
end
