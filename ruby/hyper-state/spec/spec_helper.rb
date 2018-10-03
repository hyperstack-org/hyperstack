require 'pry'
require 'opal-browser'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../test_app/config/environment', __FILE__)

require 'rspec/rails'
require 'rspec-steps'
require 'timecop'
require 'hyper-spec'
#require 'hyper-component'
#require 'hyper-store'
require 'hyper-state'


RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
end

# Stubbing after for running outside of Opal
module Hyperstack
  module Internal
    class State
      module ClassMethods
        def after(x, &block)
          blocks_to_run_after << block
        end

        def blocks_to_run_after
          @blocks_to_run_after ||= []
        end

        def run_after
          blocks_to_run_after.each(&:call)
          @blocks_to_run_after = []
        end
      end
    end
  end
end
