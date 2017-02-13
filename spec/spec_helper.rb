require 'hyper-spec'
require 'hyper-operation'
require 'pry'
#require 'opal-browser'
require 'hyper-spec'
require 'opal-browser'

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path('../test_app/config/environment', __FILE__)

require 'rspec/rails'
#require 'rspec-steps'
#require 'timecop'

module Helpers

end

module HyperSpec
  module ComponentTestHelpers
    alias old_expect_promise expect_promise
    def expect_promise(str_or_promise = nil, &block)
      if str_or_promise.is_a? Promise
        result = nil
        str_or_promise.then { |*args| result = args }
        loop do
          return expect(result.count == 1 ? result.first : result) if str_or_promise.resolved?
          sleep 0.25
        end
      else
        old_expect_promise(str_or_promise, &block)
      end
    end
  end
end

RSpec.configure do |config|
  config.include Helpers
end

RSpec::Matchers.define :have_failed_with do |expected|
  match do |promise|
    the_exception = !expected
    promise.fail { |exception| the_exception = exception }
    if expected < Exception
      expected == the_exception.class
    else
      the_exception == expected
    end
  end
end

RSpec::Matchers.define :have_succeeded_with do |*expected|
  match do |promise|
    the_results = nil
    promise.then { |*results| the_results = results }
    the_results == expected
  end
end
