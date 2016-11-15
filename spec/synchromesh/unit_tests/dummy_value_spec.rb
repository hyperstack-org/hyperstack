require 'spec_helper'
require 'synchromesh/integration/test_components'
require 'reactive_record/factory'
require 'rspec-steps'

RSpec::Steps.steps 'DummyValue', js: true do
  before(:step) do
    # spec_helper resets the policy system after each test so we have to setup
    # before each test
    # stub_const 'TestApplication', Class.new
    # stub_const 'TestApplicationPolicy', Class.new
    # TestApplicationPolicy.class_eval do
    #   always_allow_connection
    #   regulate_all_broadcasts { |policy| policy.send_all }
    #   allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    # end
    size_window(:small, :portrait)
  end

  it 'works with string interpolation (defines a JS .toString method)' do
    expect_evaluate_ruby do
      column_hash = { default: 'foo', sql_type_metadata: { type: 'text' } }
      "value = #{ReactiveRecord::Base::DummyValue.new(column_hash)}"
    end.to eq('value = foo')
  end
end
