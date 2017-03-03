require 'spec_helper'
require 'test_components'

describe "regulate access allowed" do

  context "basic tests" do
    before(:each) do
      # spec_helper resets the policy system after each test so we have to setup
      # before each test
      stub_const 'TestApplication', Class.new
      stub_const 'C2', Class.new
      stub_const 'TestApplicationPolicy', Class.new
      TestApplicationPolicy.class_eval do
        regulate_class_connection { self }
        regulate_class_connection(C2) { self }
        regulate_instance_connections(TestModel) { self if self.is_a? TestModel }
        regulate_all_broadcasts(C2) { |policy| policy.send_all_but(:created_at) }
        regulate_broadcast(TestModel) do |policy|
          policy.send_all.to(TestApplication) unless test_attribute == "bogus"
          policy.send_all.to(self)
        end
      end
    end

    it "will allow access if the broadcast policy allows access" do
      m = FactoryGirl.create(:test_model, test_attribute: "hello")
      expect { m.check_permission_with_acting_user("user", :view_permitted?, :test_attribute) }.
      not_to raise_error
      expect { m.check_permission_with_acting_user("user", :view_permitted?, :created_at) }.
      not_to raise_error
    end

    it "will disallow access if acting_user is not allowed to connect" do
      m = FactoryGirl.create(:test_model, test_attribute: "hello")
      expect { m.check_permission_with_acting_user(nil, :view_permitted?, :test_attribute) }.
      to raise_error(ReactiveRecord::AccessViolation)
      expect { m.check_permission_with_acting_user(nil, :view_permitted?, :created_at) }.
      to raise_error(ReactiveRecord::AccessViolation)
    end

    it "will disallow access to attributes not broadcast by the model" do
      m = FactoryGirl.create(:test_model, test_attribute: "bogus")
      expect { m.check_permission_with_acting_user("user", :view_permitted?, :test_attribute) }.
      not_to raise_error
      expect { m.check_permission_with_acting_user("user", :view_permitted?, :created_at) }.
      to raise_error(ReactiveRecord::AccessViolation)
    end

    it "will allow access to attributes broadcast over an instance channel" do
      m = FactoryGirl.create(:test_model, test_attribute: "bogus")
      expect { m.check_permission_with_acting_user(m, :view_permitted?, :test_attribute) }.
      not_to raise_error
      expect { m.check_permission_with_acting_user(m, :view_permitted?, :created_at) }.
      not_to raise_error
    end
  end

  it "will include :id as read attribute as long as any other attribute is readable" do
    stub_const 'TestApplication', Class.new
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_only(:test_attribute) }
    end
    m = FactoryGirl.create(:test_model)
    expect { m.check_permission_with_acting_user(nil, :view_permitted?, :id) }.
    not_to raise_error
  end

  it "will not include :id as read attribute if no other attributes are readable" do
    stub_const 'TestApplication', Class.new
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      always_allow_connection
    end
    m = FactoryGirl.create(:test_model)
    expect { m.check_permission_with_acting_user(nil, :view_permitted?, :id) }.
    to raise_error(ReactiveRecord::AccessViolation)
  end

  it "will ignore auto_connect: false " do
    stub_const 'TestApplication', Class.new
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      regulate_class_connection(auto_connect: false) { true }
      regulate_instance_connections(TestModel, auto_connect: false) { self }
      regulate_all_broadcasts { |policy| policy.send_only(:test_attribute) }
      regulate_broadcast(TestModel) { |policy| policy.send_only(:created_at).to(self) }
    end
    m = FactoryGirl.create(:test_model)
    expect { m.check_permission_with_acting_user(m, :view_permitted?, :id) }.
    not_to raise_error
    expect { m.check_permission_with_acting_user(m, :view_permitted?, :test_attribute) }.
    not_to raise_error
    expect { m.check_permission_with_acting_user(m, :view_permitted?, :created_at) }.
    not_to raise_error
  end

end
