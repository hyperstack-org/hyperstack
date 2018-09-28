require 'pry'
require 'opal-browser'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../test_app/config/environment', __FILE__)

require 'rspec/rails'
require 'rspec-steps'
require 'timecop'
#require 'hyper-spec'
#require 'hyper-component'
require 'hyper-store'


RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
end

# Stubbing the React calls so we can test outside of Opal
module Hyperstack
  module Store
    module Internal
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
  end
end
