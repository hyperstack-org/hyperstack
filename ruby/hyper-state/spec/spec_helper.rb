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
  config.after(:each) { Hyperstack::Internal::State::Mapper.reset_mapper_data }
end

# Stubbing after for running outside of Opal
module Hyperstack
  module Internal
    module State
      module Mapper

        def self.after(x, &block)
          blocks_to_run_after << block
        end

        def self.blocks_to_run_after
          @blocks_to_run_after ||= []
        end

        def self.run_after
          blocks_to_run_after.each(&:call)
          @blocks_to_run_after = []
        end

        def self.reset_mapper_data
          @blocks_to_run_after = nil
          @new_objects = nil
          @current_observers = nil
          @current_objects = nil
          @update_exclusions = nil
          @delayed_updater = nil
        end
      end
    end
  end
end
