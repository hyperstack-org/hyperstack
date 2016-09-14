require 'spec_helper'
require 'synchromesh/integration/test_components'

describe "regulate access allowed" do

  before(:each) do
    stub_const 'DummyModel', Class.new(ActiveRecord::Base)
    DummyModel.class_eval do
      self.table_name = 'test_models'
    end
  end

  after(:each) do
    load 'lib/reactive_record/permission_patches.rb'
  end

  Synchromesh::InternalClassPolicy::CHANGE_POLICIES.each do |policy|

    it "will define a basic allow_#{policy} policy" do
      stub_const 'DummyModelPolicy', Class.new
      DummyModelPolicy.class_eval do
        send("allow_#{policy}") { "called #{policy}" }
      end
      DummyModel.new.send("#{policy}_permitted?").should eq("called #{policy}")
    end

    it "will define allow_#{policy} policy with a class argument" do
      stub_const 'ApplicationPolicy', Class.new
      ApplicationPolicy.class_eval do
        send("allow_#{policy}", DummyModel) { "called #{policy}" }
      end
      DummyModel.new.send("#{policy}_permitted?").should eq("called #{policy}")
    end

    it "will define allow_#{policy} policy with the to: :all option" do
      stub_const 'ApplicationPolicy', Class.new
      ApplicationPolicy.class_eval do
        send("allow_#{policy}", to: :all) { "called #{policy} on #{self.class.name}" }
      end
      stub_const 'FooModel', Class.new(ActiveRecord::Base)
      FooModel.class_eval do
        self.table_name = 'test_models'
      end
      DummyModel.new.send("#{policy}_permitted?").should eq("called #{policy} on DummyModel")
      FooModel.new.send("#{policy}_permitted?").should eq("called #{policy} on FooModel")
    end

  end

  it "will define a basic allow_change policy" do
    stub_const 'DummyModelPolicy', Class.new
    DummyModelPolicy.class_eval do
      send("allow_change") { "called change" }
    end
    Synchromesh::InternalClassPolicy::CHANGE_POLICIES.each do |policy|
      DummyModel.new.send("#{policy}_permitted?").should eq("called change")
    end
  end

  it "will define allow_change policy with a class argument" do
    stub_const 'ApplicationPolicy', Class.new
    ApplicationPolicy.class_eval do
      send("allow_change", DummyModel) { "called change" }
    end
    Synchromesh::InternalClassPolicy::CHANGE_POLICIES.each do |policy|
      DummyModel.new.send("#{policy}_permitted?").should eq("called change")
    end
  end

  it "will define allow_change policy with the to: :all option" do
    stub_const 'ApplicationPolicy', Class.new
    ApplicationPolicy.class_eval do
      send("allow_change", to: :all) { "called change on #{self.class.name}" }
    end
    stub_const 'FooModel', Class.new(ActiveRecord::Base)
    FooModel.class_eval do
      self.table_name = 'test_models'
    end
    Synchromesh::InternalClassPolicy::CHANGE_POLICIES.each do |policy|
      DummyModel.new.send("#{policy}_permitted?").should eq("called change on DummyModel")
      FooModel.new.send("#{policy}_permitted?").should eq("called change on FooModel")
    end
  end

  it "will define allow_change policy with an :on option" do
    stub_const 'ApplicationPolicy', Class.new
    ApplicationPolicy.class_eval do
      send("allow_change", DummyModel, on: [:create, :update]) { "called change" }
    end
    [:create, :update].each do |policy|
      DummyModel.new.send("#{policy}_permitted?").should eq("called change")
    end
    DummyModel.new.send("destroy_permitted?").should be_falsy
  end

  it "will define a basic allow_read policy" do
    stub_const 'DummyModelPolicy', Class.new
    DummyModelPolicy.class_eval do
      send("allow_read") { |attr| "called read #{attr}" }
    end
    DummyModel.new.send("view_permitted?", :foo).should eq("called read foo")
  end

  it "will define allow_read policy with a class argument" do
    stub_const 'ApplicationPolicy', Class.new
    ApplicationPolicy.class_eval do
      send("allow_read", DummyModel) { |attr| "called read #{attr}" }
    end
    DummyModel.new.send("view_permitted?", :foo).should eq("called read foo")
  end

  it "will define allow_read policy with the to: :all option" do
    stub_const 'ApplicationPolicy', Class.new
    ApplicationPolicy.class_eval do
      send("allow_read", to: :all) { |attr| "called read #{attr} on #{self.class.name}" }
    end
    stub_const 'FooModel', Class.new(ActiveRecord::Base)
    FooModel.class_eval do
      self.table_name = 'test_models'
    end
    DummyModel.new.send("view_permitted?", :foo).should eq("called read foo on DummyModel")
    FooModel.new.send("view_permitted?", :foo).should eq("called read foo on FooModel")
  end

end
