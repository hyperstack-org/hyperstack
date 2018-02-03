ENV["RAILS_ENV"] ||= 'test'

require 'opal'
require 'opal-rspec'
require 'opal-jquery'

begin
  require File.expand_path('../test_app/config/environment', __FILE__)
rescue LoadError
  puts 'Could not load test application. Please ensure you have run `bundle exec rake test_app`'
end
require 'rspec/rails'
require 'hyper-spec'
require 'pry'
require 'opal-browser'
require 'timecop'

RSpec.configure do |config|
  config.color = true
  config.fail_fast = ENV['FAIL_FAST'] || false
  config.fixture_path = File.join(File.expand_path(File.dirname(__FILE__)), "fixtures")
  config.infer_spec_type_from_file_location!
  config.mock_with :rspec
  config.raise_errors_for_deprecations!

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, comment the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.before :each do
    Rails.cache.clear
  end

  config.filter_run_including focus: true
  config.filter_run_excluding opal: true
  config.run_all_when_everything_filtered = true

  # Fail tests on JavaScript errors in Chrome Headless
  class JavaScriptError < StandardError; end

  config.after(:each, js: true) do |spec|
    logs = page.driver.browser.manage.logs.get(:browser)
    errors = logs.select { |e| e.level == "SEVERE" && e.message.present? }
                .map { |m| m.message.gsub(/\\n/, "\n") }.to_a
    if client_options[:deprecation_warnings] == :on
      warnings = logs.select { |e| e.level == "WARNING" && e.message.present? }
                  .map { |m| m.message.gsub(/\\n/, "\n") }.to_a
      puts "\033[0;33;1m\nJavascript client console warnings:\n\n" + warnings.join("\n\n") + "\033[0;30;21m" if warnings.present?
    end
    unless client_options[:raise_on_js_errors] == :off
      raise JavaScriptError, errors.join("\n\n") if errors.present?
    end
  end
end
