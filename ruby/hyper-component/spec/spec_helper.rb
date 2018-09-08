require 'hyper-spec'
require 'hyper-component'
require 'pry'
require 'opal-browser'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../test_app/config/environment', __FILE__)

require 'rspec/rails'
require 'rspec-steps'
require 'timecop'

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
  config.before(:all) do
    `rm -rf spec/test_app/tmp/cache/`
  end
end

# Stubbing the React calls so we can test outside of Opal
module React
  class State
    class << self
      def reset!
        @states = nil
      end

      def get_state(from, key)
        states[from] ||= {}
        states[from][key.to_s]
      end

      def set_state(from, key, value)
        states[from] ||= {}
        states[from][key.to_s] = value
      end

      def states
        @states ||= {}
      end
    end
  end
end
