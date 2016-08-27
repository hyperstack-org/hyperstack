require 'spec_helper'
#require 'synchromesh/test_components'

describe "including Synchromesh::PolicyMethods" do

  before(:each) do
    stub_const "TestClass", Class.new
    TestClass.class_eval do
      include Synchromesh::PolicyMethods
    end
  end

  it "defines the regulate_connection method" do
    expect(TestClass).to respond_to(:regulate_connection)
  end

  it "defines the regulate_all_broadcasts method" do
    expect(TestClass).to respond_to(:regulate_all_broadcasts)
  end

  it "defines the regulate_broadcast method" do
    expect(TestClass).to respond_to(:regulate_broadcast)
  end

  it "sets the correct regulated class" do
    expect(TestClass.synchromesh_internal_policy_object.instance_variable_get("@regulated_klass")).to eq("TestClass")
  end

  it "exposes the underlying regulate_connection method" do
    expect(TestClass.synchromesh_internal_policy_object).to respond_to(:regulate_connection)
  end

  it "exposes the underlying regulate_all_broadcasts method" do
    expect(TestClass.synchromesh_internal_policy_object).to respond_to(:regulate_all_broadcasts)
  end

  it "exposes the underlying regulate_broadcast method" do
    expect(TestClass.synchromesh_internal_policy_object).to respond_to(:regulate_broadcast)
  end

  it "defines the send_all instance method" do
    expect(TestClass.new).to respond_to(:send_all)
  end

  it "defines the send_all_but instance method" do
    expect(TestClass.new).to respond_to(:send_all_but)
  end

  it "defines the send_only instance method" do
    expect(TestClass.new).to respond_to(:send_only)
  end

  it "defines the obj instance method" do
    expect(TestClass.new).to respond_to(:obj)
  end

end
