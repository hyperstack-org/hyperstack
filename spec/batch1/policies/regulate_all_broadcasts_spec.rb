require 'spec_helper'

describe "regulate_all_broadcasts" do

  before(:each) do
    stub_const "TestModel1", Class.new
    TestModel1.class_eval do
      include ActiveModel::Model
      def react_serializer
        as_json # does not include type: xxx as per reactive-record
      end
      def previous_changes
        Hash[*as_json.keys.collect { |attr| [attr, send(attr)] }.flatten(1)]
      end
      def attribute_names
        [:attr1, :attr2, :attr3, :attr4, :attr5]
      end
      attr_accessor :attr1, :attr2, :attr3, :attr4, :attr5
    end
    stub_const "TestModel2", Class.new
    TestModel2.class_eval do
      include ActiveModel::Model
      def react_serializer
        as_json # does not include type: xxx as per reactive-record
      end
      def previous_changes
        Hash[*as_json.keys.collect { |attr| [attr, send(attr)] }.flatten(1)]
      end
      def attribute_names
        [:attrA, :attrB, :attrC, :attrD, :attrE]
      end
      attr_accessor :attrA, :attrB, :attrC, :attrD, :attrE
    end
    allow_any_instance_of(Hyperloop::InternalPolicy).to receive(:id).and_return(:unique_broadcast_id)
    allow(Hyperloop::Connection).to receive(:active).and_return(['Application', 'AnotherApplication', 'Class1', 'Class2'])
  end

  it "will broadcast to a single channel" do
    stub_const "ApplicationPolicy", Class.new
    ApplicationPolicy.class_eval do
      regulate_all_broadcasts do | policy |
        policy.send_all
      end
    end
    model = TestModel1.new(attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperloop::InternalPolicy.regulate_broadcast(model, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'Application',
        channels: ['Application'],
        klass: 'TestModel1',
        record: {attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5},
        previous_changes: {attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5}
      }
    )
  end

  it "will broadcast to a multiple channels" do
    stub_const "ApplicationPolicy", Class.new
    ApplicationPolicy.class_eval do
      regulate_all_broadcasts do | policy |
        policy.send_all
      end
    end
    stub_const "AnotherApplicationPolicy", Class.new
    AnotherApplicationPolicy.class_eval do
      regulate_all_broadcasts do | policy |
        policy.send_all
      end
    end
    model = TestModel1.new(attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperloop::InternalPolicy.regulate_broadcast(model, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'Application',
        channels: ['Application', 'AnotherApplication'],
        klass: 'TestModel1',
        record: {attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5},
        previous_changes: {attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5}
      },
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'AnotherApplication',
        channels: ['Application', 'AnotherApplication'],
        klass: 'TestModel1',
        record: {attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5},
        previous_changes: {attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5}
      }
    )
  end

  it "will broadcast to a multiple channels with different attributes" do
    stub_const "ApplicationPolicy", Class.new
    ApplicationPolicy.class_eval do
      regulate_all_broadcasts do | policy |
        policy.send_only(:attr1)
      end
    end
    stub_const "AnotherApplicationPolicy", Class.new
    AnotherApplicationPolicy.class_eval do
      regulate_all_broadcasts do | policy |
        policy.send_all_but(:attr1)
      end
    end
    model = TestModel1.new(attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperloop::InternalPolicy.regulate_broadcast(model, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'Application',
        channels: ['Application', 'AnotherApplication'],
        klass: 'TestModel1',
        record: {attr1: 1},
        previous_changes: {attr1: 1}
      },
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'AnotherApplication',
        channels: ['Application', 'AnotherApplication'],
        klass: 'TestModel1',
        record: {attr2: 2, attr3: 3, attr4: 4, attr5: 5},
        previous_changes: {attr2: 2, attr3: 3, attr4: 4, attr5: 5}
      }
    )
  end

  it "can override the default channel using the 'to' method" do
    stub_const "ApplicationPolicy", Class.new
    stub_const "AnotherApplicationPolicy", Class.new
    stub_const "Application", Class.new
    stub_const "AnotherApplication", Class.new
    ApplicationPolicy.class_eval do
      regulate_all_broadcasts do | policy |
        policy.send_only(:attr1).to(AnotherApplication)
      end
    end
    AnotherApplicationPolicy.class_eval do
      regulate_all_broadcasts do | policy |
        policy.send_all_but(:attr1).to(Application)
      end
    end
    model = TestModel1.new(attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperloop::InternalPolicy.regulate_broadcast(model, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'AnotherApplication',
        channels: ['AnotherApplication', 'Application'],
        klass: 'TestModel1',
        record: {attr1: 1},
        previous_changes: {attr1: 1}
      },
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'Application',
        channels: ['AnotherApplication', 'Application'],
        klass: 'TestModel1',
        record: {attr2: 2, attr3: 3, attr4: 4, attr5: 5},
        previous_changes: {attr2: 2, attr3: 3, attr4: 4, attr5: 5}
      }
    )
  end

  it "can have multiple polcies" do
    stub_const "ApplicationPolicy", Class.new
    stub_const "AnotherApplicationPolicy", Class.new
    stub_const "Application", Class.new
    stub_const "AnotherApplication", Class.new
    ApplicationPolicy.class_eval do
      regulate_all_broadcasts do | policy |
        policy.send_only(:attr1, :attr2, :attr3).to(AnotherApplication)
      end
    end
    AnotherApplicationPolicy.class_eval do
      regulate_all_broadcasts do | policy |
        policy.send_all_but(:attr1).to(AnotherApplication, Application)
      end
    end
    model = TestModel1.new(attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperloop::InternalPolicy.regulate_broadcast(model, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'AnotherApplication',
        channels: ['AnotherApplication', 'Application'],
        klass: 'TestModel1',
        record: {attr2: 2, attr3: 3},
        previous_changes: {attr2: 2, attr3: 3}
      },
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'Application',
        channels: ['AnotherApplication', 'Application'],
        klass: 'TestModel1',
        record: {attr2: 2, attr3: 3, attr4: 4, attr5: 5},
        previous_changes: {attr2: 2, attr3: 3, attr4: 4, attr5: 5}
      }
    )
  end

  it "can have multiple polcies defined by separate send policies" do
    stub_const "ApplicationPolicy", Class.new
    stub_const "AnotherApplicationPolicy", Class.new
    stub_const "Application", Class.new
    stub_const "AnotherApplication", Class.new
    ApplicationPolicy.class_eval do
      regulate_all_broadcasts do | policy |
        policy.send_only(:attr1, :attr2, :attr3).to(AnotherApplication)
      end
    end
    AnotherApplicationPolicy.class_eval do
      regulate_all_broadcasts do | policy |
        policy.send_all_but(:attr1).to(Application)
        policy.send_all_but(:attr1)
      end
    end
    model = TestModel1.new(attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperloop::InternalPolicy.regulate_broadcast(model, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'AnotherApplication',
        channels: ['AnotherApplication', 'Application'],
        klass: 'TestModel1',
        record: {attr2: 2, attr3: 3},
        previous_changes: {attr2: 2, attr3: 3}
      },
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'Application',
        channels: ['AnotherApplication', 'Application'],
        klass: 'TestModel1',
        record: {attr2: 2, attr3: 3, attr4: 4, attr5: 5},
        previous_changes: {attr2: 2, attr3: 3, attr4: 4, attr5: 5}
      }
    )
  end

  it "can have multiple policies without any to method and will intersect the results" do
    stub_const "ApplicationPolicy", Class.new
    ApplicationPolicy.class_eval do
      regulate_all_broadcasts do | policy |
        policy.send_only(:attr1, :attr2)
        policy.send_only(:attr2, :attr3)
      end
    end
    model = TestModel1.new(attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperloop::InternalPolicy.regulate_broadcast(model, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'Application',
        channels: ['Application'],
        klass: 'TestModel1',
        record: {attr2: 2},
        previous_changes: {attr2: 2}
      }
    )
  end

  it "can have apply the same policies to different models" do
    stub_const "ApplicationPolicy", Class.new
    ApplicationPolicy.class_eval do
      regulate_all_broadcasts do | policy |
        policy.send_only(:attr1, :attrA)
      end
    end
    model = TestModel1.new(attr1: 1)
    expect { |b| Hyperloop::InternalPolicy.regulate_broadcast(model, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'Application',
        channels: ['Application'],
        klass: 'TestModel1',
        record: {attr1: 1},
        previous_changes: {attr1: 1}
      }
    )
    model = TestModel2.new(attrA: "A")
    expect { |b| Hyperloop::InternalPolicy.regulate_broadcast(model, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'Application',
        channels: ['Application'],
        klass: 'TestModel2',
        record: {attrA: "A"},
        previous_changes: {attrA: "A"}
      }
    )
  end
  it "will accept a list of classes to apply the policy to" do
    stub_const "ApplicationPolicy", Class.new
    stub_const "Class1", Class.new
    stub_const "Class2", Class.new
    ApplicationPolicy.class_eval do
      regulate_all_broadcasts(Class1, Class2) do | policy |
        policy.send_all
      end
    end
    model = TestModel1.new(attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5)
    expect { |b| Hyperloop::InternalPolicy.regulate_broadcast(model, &b) }.to yield_successive_args(
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'Class1',
        channels: ['Class1', 'Class2'],
        klass: 'TestModel1',
        record: {attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5},
        previous_changes: {attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5}
      },
      {
        broadcast_id: :unique_broadcast_id,
        channel: 'Class2',
        channels: ['Class1', 'Class2'],
        klass: 'TestModel1',
        record: {attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5},
        previous_changes: {attr1: 1, attr2: 2, attr3: 3, attr4: 4, attr5: 5}
      }
    )
  end
end
