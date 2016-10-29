require 'spec_helper'
#Opal::RSpec::Runner.autorun
class Thing < ActiveRecord::Base
end

describe "ActiveRecord" do
  before(:each) { React::IsomorphicHelpers.load_context }
  let(:instance) { Thing.new({attr1: 1, attr2: 2, id: 123}) }
  after(:each) { React::API.clear_component_class_cache }

  # uncomment if you are having trouble with tests failing.  One non-async test must pass for things to work

  # describe "a passing dummy test" do
  #   it "passes" do
  #     expect(true).to be(true)
  #   end
  # end

  describe "Instance Methods" do

    it "will have the attributes loaded" do
      expect(instance.attr1).to eq(1)
    end

    it "will not have a primary key if loaded from a hash" do
      expect(instance.id).to be(nil)
    end

    it "reports being changed if new" do
      expect(instance.changed?).to be_truthy
    end

    it "reports not being changed if loaded from db" do
      expect(Thing.find(123).changed?).to be_falsy
    end

    it "reports being changed, if I do change it" do
      Thing.find(1234).my_attribute = "new"
      expect(Thing.find(1234).changed?).to be_truthy
    end

    it "does not think things are destroyed" do
      expect(instance).not_to be_destroyed
    end

    it "can destroy things" do
      instance.destroy
      expect(instance).to be_destroyed
    end

  end

end
