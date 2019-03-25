require 'spec_helper'

describe 'rescues macro', js: true do

  before(:each) do
    client_option raise_on_js_errors: :off
  end

  it 'will run the block when an error is raised' do
    mount 'Test' do
      class Test < Hyperloop::Component
        render(DIV) do
          raise 'explosion' unless @some_state
          'FALLBACK'
        end
        rescues do
          @some_state = true
        end
      end
    end
    expect(page).to have_content('FALLBACK')
  end

  it 'will catch specific errors' do
    mount 'Test' do
      class MyError < Exception; end
      class OtherError < Exception; end

      class InnerTest < Hyperloop::Component
        class << self
          attr_accessor :test_failed
        end
        param :dont_fail
        render(DIV) do
          raise MyError unless @DontFail
          'NO FAIL'
        end
        rescues OtherError do
          InnerTest.test_failed = true
        end
      end

      class Test < Hyperloop::Component
        render(DIV) do
          InnerTest(dont_fail: @dont_fail)
        end
        rescues MyError do
          @dont_fail = true
        end
      end
    end
    expect(page).to have_content('NO FAIL')
    expect_evaluate_ruby("InnerTest.test_failed").to be_falsy
  end

  it 'will pass the error to the block' do
    mount 'Test' do
      class MyError < Exception; end
      class Test < Hyperloop::Component
        render(DIV) do
          raise MyError, "error data" unless @err_data
          "FALLBACK #{@err_data}"
        end
        rescues MyError do |err_data|
          @err_data = err_data
        end
      end
    end
    expect(page).to have_content('FALLBACK MyError: error data')
  end

  it 'will catch several error types with the same block' do
    mount 'Test' do
      class MyError < Exception; end
      class OtherError < Exception; end

      class InnerTest < Hyperloop::Component
        param :err_type
        render(DIV) do
          raise Object.const_get(@ErrType) unless @err
          @err
        end
        rescues MyError, OtherError do |err|
          @err = err.to_s
        end
      end

      class Test < Hyperloop::Component
        render(DIV) do
          InnerTest(err_type: 'MyError')
          InnerTest(err_type: 'OtherError')
        end
      end
    end
    expect(page).to have_content('MyError')
    expect(page).to have_content('OtherError')
  end

end
