ENV["RAILS_ENV"] ||= 'test'

require 'opal'
require 'opal-rspec'
require 'opal-jquery'

if RUBY_ENGINE == 'opal'
  require File.expand_path('../vendor/jquery-2.2.4.min', __FILE__)
  require 'hyperloop-config'
  Hyperloop::Context
  require 'react/react-source-browser'
  require 'react/react-source-server'
  require 'hyper-react'
  require 'react/test/rspec'
  require 'react/test/utils'
  require 'react/top_level_render'
  require 'react/ref_callback'
  require 'react/server'

  require File.expand_path('../support/react/spec_helpers', __FILE__)

  # turn off deprecation warnings for old style name spaces during this test
  module React
    module Component

      def self.included(base)
        # deprecation_warning base, "The module name React::Component has been deprecated.  Use Hyperloop::Component::Mixin instead."
        base.include Hyperloop::Component::Mixin
      end

      class Base
        def self.inherited(child)
          # unless child.to_s == "React::Component::HyperTestDummy"
          #   React::Component.deprecation_warning child, "The class name React::Component::Base has been deprecated.  Use Hyperloop::Component instead."
          # end
          child.include(ComponentNoNotice)
        end
      end
    end
  end

  module React
    class State
      # this messes with lots of tests, these tests will be retested in the new hyper-component gem tests
      ALWAYS_UPDATE_STATE_AFTER_RENDER = false
    end
  end

  module Opal
    module RSpec
      module AsyncHelpers
        module ClassMethods
          def rendering(title, &block)
            klass = Class.new do
              include React::Component

              def self.block
                @block
              end

              def self.name
                "dummy class"
              end

              def render
                instance_eval &self.class.block
              end

              def self.should_generate(opts={}, &block)
                sself = self
                @self.async(@title, opts) do
                  expect_component_to_eventually(sself, &block)
                end
              end

              def self.should_immediately_generate(opts={}, &block)
                sself = self
                @self.it(@title, opts) do
                  element = build_element sself, {}
                  context = block.arity > 0 ? self : element
                  expect((element and context.instance_exec(element, &block))).to be(true)
                end
              end

            end
            klass.instance_variable_set("@block", block)
            klass.instance_variable_set("@self", self)
            klass.instance_variable_set("@title", "it can render #{title}")
            klass
          end
        end
      end
    end
  end


  RSpec.configure do |config|
    config.include React::SpecHelpers
    config.filter_run_excluding :ruby
    if `(React.version.search(/^0\.13/) === -1)`
      config.filter_run_excluding :v13_only
    else
      config.filter_run_excluding :v13_exclude
    end
  end
end

if RUBY_ENGINE != 'opal'
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

  Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

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
      if client_options[:raise_on_js_errors] == :off
        puts "\033[0;31;1m\nJavascript client console warnings:\n\n" + errors.join("\n\n") + "\033[0;30;21m" if erros.present?
      else
        raise JavaScriptError, errors.join("\n\n") if errors.present?
      end
    end
  end
end
