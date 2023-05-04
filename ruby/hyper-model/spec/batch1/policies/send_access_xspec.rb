require 'spec_helper'
#require 'synchromesh/test_components'

describe "regulate_broadcast" do

  before(:each) do
    stub_const "TestModel1", Class.new
    TestModel1.class_eval do
      include ActiveModel::Model
      def react_serializer
        as_json # does not include type: xxx as per reactive-record
      end
      def attribute_names
        [:id, :attr1, :attr2, :attr3, :attr4, :attr5]
      end
      def saved_changes
        Hash[*as_json.keys.collect { |attr| [attr, send(attr)] }.flatten(1)]
      end
      attr_accessor :id, :attr1, :attr2, :attr3, :attr4, :attr5
    end
    stub_const "TestModel2", Class.new
    TestModel2.class_eval do
      include ActiveModel::Model
      def react_serializer
        as_json # does not include type: xxx as per reactive-record
      end
      def attribute_names
        [:id, :attrA, :attrB, :attrC, :attrD, :attrE]
      end
      def saved_changes
        Hash[*as_json.keys.collect { |attr| [attr, send(attr)] }.flatten(1)]
      end
      attr_accessor :id, :attrA, :attrB, :attrC, :attrD, :attrE
    end
    allow(Hyperstack::Connection).to receive(:active).and_return(['Application', 'TestModel1-1', 'TestModel1-7', 'TestModel2-8'])
    allow_any_instance_of(Hyperstack::InternalPolicy).to receive(:id).and_return(:unique_broadcast_id)
  end

  it "will allow sending an attribute to a record"
  it "will allow sending a relationship to a model"
  it "will allow sending a scope to a model"
  it "will allow sending a relationship to a relationship or scope"
  it "will allow sending a server method to a model"
  it "will allow sending count to model"
  it "will allow sending count to relationship" do
    stub_const "TestModel1Policy", Class.new
    TestModel1Policy.class_eval do
      regulate_broadcast do | policy |
        policy.send_all.to(self)
      end
    end
    model = TestModel1.new(id: 1, attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperstack::InternalPolicy.regulate_broadcast(model, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'TestModel1-1',
        channels: ['TestModel1-1'],
        klass: 'TestModel1',
        record: {id: 1, attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5},
        previous_changes: {id: 1, attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5}
      }
    )
  end

  it "will raise an error if the policy is not sent" do
    stub_const "TestModel1Policy", Class.new
    TestModel1Policy.class_eval do
      regulate_broadcast do | policy |
        policy.send_all
      end
    end
    model = TestModel1.new(id: 1, attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperstack::InternalPolicy.regulate_broadcast(model, &b) }.
    to raise_error("TestModel1 instance broadcast policy not sent to any channel")
  end

  it "will intersect all policies for the same channel" do
    stub_const "TestModel1Policy", Class.new
    TestModel1Policy.class_eval do
      regulate_broadcast do | policy |
        policy.send_only(:attr1, :attr2).to(self)
        policy.send_only(:attr2, :attr3).to(self)
      end
    end
    model = TestModel1.new(id: 1, attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperstack::InternalPolicy.regulate_broadcast(model, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'TestModel1-1',
        channels: ['TestModel1-1'],
        klass: 'TestModel1',
        record: {id: 1, attr2: 2},
        previous_changes: {id: 1, attr2: 2}
      }
    )
  end

  it "will broadcast the instance policies for a model and on a class channel" do
    stub_const "TestModel1Policy", Class.new
    stub_const "Application", Class.new
    TestModel1Policy.class_eval do
      regulate_broadcast do | policy |
        policy.send_all.to(self, Application)
      end
    end
    model = TestModel1.new(id: 1, attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperstack::InternalPolicy.regulate_broadcast(model, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'TestModel1-1',
        channels: ['TestModel1-1', 'Application'],
        klass: 'TestModel1',
        record: {id: 1, attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5},
        previous_changes: {id: 1, attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5}
      },
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'Application',
        channels: ['TestModel1-1', 'Application'],
        klass: 'TestModel1',
        record: {id: 1, attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5},
        previous_changes: {id: 1, attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5}
      }
    )
  end

  it "will handle arrays and falsy values in the to method" do
    stub_const "TestModel1Policy", Class.new
    stub_const "Application", Class.new
    TestModel1Policy.class_eval do
      regulate_broadcast do | policy |
        policy.send_all.to(false, [self, Application], nil)
      end
    end
    model = TestModel1.new(id: 1, attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperstack::InternalPolicy.regulate_broadcast(model, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'TestModel1-1',
        channels: ['TestModel1-1', 'Application'],
        klass: 'TestModel1',
        record: {id: 1, attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5},
        previous_changes: {id: 1, attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5}
      },
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'Application',
        channels: ['TestModel1-1', 'Application'],
        klass: 'TestModel1',
        record: {id: 1, attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5},
        previous_changes: {id: 1, attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5}
      }
    )
  end

  it "will broadcast different instance policies on different channels" do
    stub_const "TestModel1Policy", Class.new
    stub_const "Application", Class.new
    TestModel1Policy.class_eval do
      regulate_broadcast do | policy |
        policy.send_all.to(self)
        policy.send_only(:id).to(Application)
      end
    end
    model = TestModel1.new(id: 1, attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperstack::InternalPolicy.regulate_broadcast(model, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'TestModel1-1',
        channels: ['TestModel1-1', 'Application'],
        klass: 'TestModel1',
        record: {id: 1, attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5},
        previous_changes: {id: 1, attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5}
      },
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'Application',
        channels: ['TestModel1-1', 'Application'],
        klass: 'TestModel1',
        record: {id: 1},
        previous_changes: {id: 1}
      }
    )
  end

  it "will pass the proper policy object" do
    stub_const "TestModel1Policy", Class.new
    stub_const "Application", Class.new
    TestModel1Policy.class_eval do
      def public_attributes
        [:id]
      end
      regulate_broadcast do | policy |
        policy.send_all.to(self)
        policy.send_only(*policy.public_attributes).to(Application)
      end
    end
    model = TestModel1.new(id: 1, attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperstack::InternalPolicy.regulate_broadcast(model, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'TestModel1-1',
        channels: ['TestModel1-1', 'Application'],
        klass: 'TestModel1',
        record: {id: 1, attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5},
        previous_changes: {id: 1, attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5}
      },
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'Application',
        channels: ['TestModel1-1', 'Application'],
        klass: 'TestModel1',
        record: {id: 1},
        previous_changes: {id: 1}
      }
    )
  end

  it "will evaluates the regulation in the context of model being broadcast" do
    stub_const "TestModel1Policy", Class.new
    stub_const "Application", Class.new
    TestModel1Policy.class_eval do
      def public_attributes
        [:id]
      end
      regulate_broadcast do | policy |
        policy.send_all_but(:attr2).to(self) if attr2 == "YES"
      end
    end
    model = TestModel1.new(id: 1, attr1: 1, attr2: "YES", attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperstack::InternalPolicy.regulate_broadcast(model, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'TestModel1-1',
        channels: ['TestModel1-1'],
        klass: 'TestModel1',
        record: {id: 1, attr1: 1, attr3: 3, attr4: 4, attr5: 5},
        previous_changes: {id: 1, attr1: 1, attr3: 3, attr4: 4, attr5: 5}
      }
    )
    model = TestModel1.new(id: 1, attr1: 1, attr2: "NO", attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperstack::InternalPolicy.regulate_broadcast(model, &b) }.not_to yield_control
  end

  it "will adds the obj method to the policy which points back to the model being broadcast" do
    stub_const "TestModel1Policy", Class.new
    stub_const "Application", Class.new
    TestModel1Policy.class_eval do
      def send?
        obj.attr2 == "YES"
      end
      regulate_broadcast do | policy |
        policy.send_all_but(:attr2).to(self) if policy.send?
      end
    end
    model = TestModel1.new(id: 1, attr1: 1, attr2: "YES", attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperstack::InternalPolicy.regulate_broadcast(model, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'TestModel1-1',
        channels: ['TestModel1-1'],
        klass: 'TestModel1',
        record: {id: 1, attr1: 1, attr3: 3, attr4: 4, attr5: 5},
        previous_changes: {id: 1, attr1: 1, attr3: 3, attr4: 4, attr5: 5}
      }
    )
    model = TestModel1.new(id: 1, attr1: 1, attr2: "NO", attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperstack::InternalPolicy.regulate_broadcast(model, &b) }.not_to yield_control
  end
  it "will not broadcast an empty record" do
    stub_const "TestModel1Policy", Class.new
    stub_const "Application", Class.new
    TestModel1Policy.class_eval do
      def attributes_to_send
        [:attr1] if obj.attr2 == "YES"
      end
      regulate_broadcast do | policy |
        policy.send_only(*policy.attributes_to_send).to(self)
      end
    end
    model = TestModel1.new(id: 1, attr1: 1, attr2: "YES", attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperstack::InternalPolicy.regulate_broadcast(model, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'TestModel1-1',
        channels: ['TestModel1-1'],
        klass: 'TestModel1',
        record: {id: 1, attr1: 1},
        previous_changes: {id: 1, attr1: 1}
      }
    )
    model = TestModel1.new(id: 1, attr1: 1, attr2: "NO", attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperstack::InternalPolicy.regulate_broadcast(model, &b) }.not_to yield_control
  end
  it "will apply the same policy to several models" do
    stub_const "ApplicationPolicy", Class.new
    ApplicationPolicy.class_eval do
      regulate_broadcast(TestModel1, TestModel2) do |policy|
        policy.send_all_but(:attr1).to(self)
      end
    end
    model1 = TestModel1.new(id: 7, attr1: 1)
    model2 = TestModel2.new(id: 8, attrA: 1)
    expect { |b| Hyperstack::InternalPolicy.regulate_broadcast(model1, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'TestModel1-7',
        channels: ['TestModel1-7'],
        klass: 'TestModel1',
        record: {id: 7},
        previous_changes: {id: 7}
      }
    )
    expect { |b| Hyperstack::InternalPolicy.regulate_broadcast(model2, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'TestModel2-8',
        channels: ['TestModel2-8'],
        klass: 'TestModel2',
        record: {id: 8, attrA: 1},
        previous_changes: {id: 8, attrA: 1}
      }
    )

  end

  it "exposes the policy methods on the hyperstack_internal_policy_object" do
    stub_const "TestModel1Policy", Class.new
    stub_const "Application", Class.new
    TestModel1Policy.class_eval do
      regulate_broadcast do | policy |
        case policy.hyperstack_internal_policy_object.obj.attr1
        when "send_all"
          policy.hyperstack_internal_policy_object.send_all.to(self)
        when "send_all_but"
          policy.hyperstack_internal_policy_object.send_all_but(:attr2).to(self)
        when "send_only"
          policy.hyperstack_internal_policy_object.send_only(:attr2).to(self)
        end
      end
    end
    model = TestModel1.new(id: 1, attr1: "send_all", attr2: "YES", attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperstack::InternalPolicy.regulate_broadcast(model, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'TestModel1-1',
        channels: ['TestModel1-1'],
        klass: 'TestModel1',
        record: {id: 1, attr1: "send_all", attr2: "YES", attr3: 3, attr4: 4, attr5: 5},
        previous_changes: {id: 1, attr1: "send_all", attr2: "YES", attr3: 3, attr4: 4, attr5: 5}
      }
    )
    model = TestModel1.new(id: 1, attr1: "send_all_but", attr2: "YES", attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperstack::InternalPolicy.regulate_broadcast(model, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'TestModel1-1',
        channels: ['TestModel1-1'],
        klass: 'TestModel1',
        record: {id: 1, attr1: "send_all_but", attr3: 3, attr4: 4, attr5: 5},
        previous_changes: {id: 1, attr1: "send_all_but", attr3: 3, attr4: 4, attr5: 5}
      }
    )
    model = TestModel1.new(id: 1, attr1: "send_only", attr2: "YES", attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperstack::InternalPolicy.regulate_broadcast(model, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'TestModel1-1',
        channels: ['TestModel1-1'],
        klass: 'TestModel1',
        record: {id: 1, attr2: "YES"},
        previous_changes: {id: 1, attr2: "YES"}
      }
    )
  end
end
