require 'spec_helper'

describe 'channel auto connect' do

  before(:each) do
    stub_const 'ApplicationPolicy', Class.new
    stub_const 'TestModelPolicy', Class.new
    stub_const 'TestModel', Class.new
    TestModel.class_eval do
      def initialize(id)
        @id = id
      end
      def self.find(id)
        new(id)
      end
      def id
        @id
      end
    end
  end

  it 'will autoconnect' do
    ApplicationPolicy.always_allow_connection
    expect(Synchromesh::AutoConnect.channels(nil)).to eq(["Application"])
  end

  it 'will autoconnect to multiple channels' do
    ApplicationPolicy.regulate_class_connection { true }
    ApplicationPolicy.regulate_class_connection('AnotherChannel') { true }
    expect(Synchromesh::AutoConnect.channels(nil)).to eq(['Application', 'AnotherChannel'])
  end

  it 'will not autoconnect if disabled' do
    ApplicationPolicy.regulate_class_connection(auto_connect: false) { true }
    ApplicationPolicy.regulate_instance_connections(TestModel) { self }
    expect(Synchromesh::AutoConnect.channels(TestModel.find(1))).to eq([['TestModel',1]])
  end

  it 'can autoconnect to an instance' do
    TestModelPolicy.regulate_instance_connections { self }
    expect(Synchromesh::AutoConnect.channels(TestModel.find(1))).to eq([['TestModel', 1]])
  end

  it 'can autoconnect to an instance and class' do
    TestModelPolicy.always_allow_connection
    TestModelPolicy.regulate_instance_connections { self }
    expect(Synchromesh::AutoConnect.channels(TestModel.find(1))).to eq(['TestModel', ['TestModel', 1]])
  end

  it 'can autoconnect to multiple instances' do
    TestModelPolicy.regulate_instance_connections { [TestModel.find(1), TestModel.find(2)] if self == 'acting_user'}
    expect(Synchromesh::AutoConnect.channels('acting_user')).to eq([['TestModel', 1], ['TestModel', 2]])
  end
end
