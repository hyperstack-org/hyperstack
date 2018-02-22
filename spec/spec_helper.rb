ENV["RAILS_ENV"] ||= 'test'
require File.expand_path('../test_app/config/environment', __FILE__)
require 'rspec/rails'
require 'hyper-spec'

RSpec.configure do |config|

  # Fail tests on JavaScript errors in Chrome Headless
  # class JavaScriptError < StandardError; end

  # config.after(:each, js: true) do |spec|
  #   logs = page.driver.browser.manage.logs.get(:browser)
  #   errors = logs.select { |e| e.level == "SEVERE" && e.message.present? }
  #               .map { |m| m.message.gsub(/\\n/, "\n") }.to_a
  #   if client_options[:deprecation_warnings] == :on
  #     warnings = logs.select { |e| e.level == "WARNING" && e.message.present? }
  #                 .map { |m| m.message.gsub(/\\n/, "\n") }.to_a
  #     puts "\033[0;33;1m\nJavascript client console warnings:\n\n" + warnings.join("\n\n") + "\033[0;30;21m" if warnings.present?
  #   end
  #   unless client_options[:raise_on_js_errors] == :off
  #     raise JavaScriptError, errors.join("\n\n") if errors.present?
  #   end
  # end
end
