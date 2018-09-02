require 'spec_helper'
require 'rspec-steps'

RSpec::Steps.steps 'Aggregation Reflection', js: true do

  it "knows the aggregates class" do
    expect_evaluate_ruby do
      User.reflect_on_aggregation(:address).klass
    end.to eq('Address')
  end

  it "knows the aggregates attribute" do
    expect_evaluate_ruby do
      User.reflect_on_aggregation(:address).attribute
    end.to eq('address')
  end

  it "knows all the Aggregates" do
    expect_evaluate_ruby do
      User.reflect_on_all_aggregations.count
    end.to eq(3)
  end
end
