require 'spec_helper'

describe "including Hyperloop::PolicyMethods" do

  before(:each) do
    stub_const "TestClass", Class.new
    TestClass.class_eval do
      include Hyperloop::PolicyMethods
    end
  end

  it "defines the regulate_class_connection method" do
    expect(TestClass).to respond_to(:regulate_class_connection)
  end


  it "defines the regulate_instance_connections method" do
    expect(TestClass).to respond_to(:regulate_instance_connections)
  end

  it "defines the always_allow_connection method" do
    expect(TestClass).to respond_to(:always_allow_connection)
  end

  it "defines the regulate_all_broadcasts method" do
    expect(TestClass).to respond_to(:regulate_all_broadcasts)
  end

  it "defines the regulate_broadcast method" do
    expect(TestClass).to respond_to(:regulate_broadcast)
  end

  it "sets the correct regulated class" do
    expect(TestClass.hyperloop_internal_policy_object.instance_variable_get("@regulated_klass")).to eq("TestClass")
  end

  it "exposes the underlying regulate_class_connection method" do
    expect(TestClass.hyperloop_internal_policy_object).to respond_to(:regulate_class_connection)
  end


  it "exposes the underlying regulate_instance_connections method" do
    expect(TestClass.hyperloop_internal_policy_object).to respond_to(:regulate_instance_connections)
  end

  it "exposes the underlying always_allow_connection method" do
    expect(TestClass.hyperloop_internal_policy_object).to respond_to(:always_allow_connection)
  end

  it "exposes the underlying regulate_all_broadcasts method" do
    expect(TestClass.hyperloop_internal_policy_object).to respond_to(:regulate_all_broadcasts)
  end

  it "exposes the underlying regulate_broadcast method" do
    expect(TestClass.hyperloop_internal_policy_object).to respond_to(:regulate_broadcast)
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

  it "will automatically create an empty Application class if needed" do
    expect(defined? Application).to be_falsy
    stub_const 'ApplicationPolicy', Class.new
    ApplicationPolicy.class_eval do
      regulate_class_connection { true }
    end
    Hyperloop.configuration {}
    expect(Application).to be_a(Class)
  end

end
