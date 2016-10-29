require 'spec_helper'
#require 'active_record'
#Opal::RSpec::Runner.autorun

class Thing < ActiveRecord::Base
end

class ThingContainer < ActiveRecord::Base
  composed_of :thing
  composed_of :another_thing, :class_name => Thing
end


describe "ActiveRecord" do
  after(:each) { React::API.clear_component_class_cache }

  # uncomment if you are having trouble with tests failing.  One non-async test must pass for things to work

  # describe "a passing dummy test" do
  #   it "passes" do
  #     expect(true).to be(true)
  #   end
  # end

  describe "Aggregation Reflection" do

    it "knows the aggregates class" do
      expect(ThingContainer.reflect_on_aggregation(:thing).klass).to eq(Thing)
    end

    it "knows the aggregates attribute" do
      expect(ThingContainer.reflect_on_aggregation(:thing).attribute).to eq(:thing)
    end

    it "knows all the Aggregates" do
      expect(ThingContainer.reflect_on_all_aggregations.count).to eq(2)
    end

  end

end
