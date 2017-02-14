require 'hyper-spec'
require 'hyper-store'
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

class HyperOperation
  class << self
    def on_dispatch(&block)
      receivers << block
    end

    def receivers
      @receivers ||= []
    end

    def dispatch(params = {})
      receivers.each do |receiver|
        receiver.call params
      end
    end
  end

  def dispatch(params = {})
    self.class.receivers.each do |receiver|
      receiver.call params
    end
  end
end

module HyperLoop
  class Boot < HyperOperation
  end
end
