require 'spec_helper'
#require 'synchromesh/test_components'

describe "regulate_instance_connections" do

  before(:each) do
    stub_const "ApplicationPolicy", Class.new
    stub_const "Application", Class.new
    Application.class_eval do
      def initialize(id)
        @id = id
      end
      def ==(other)
        id == other.id
      end
      def self.find(id)
        new(id)
      end
      def id
        @id.to_s
      end
    end
  end

  it "will fail for an instance connection if the connection policy does not support instances" do
    ApplicationPolicy.always_allow_connection
    expect { Synchromesh::InternalPolicy.regulate_connection(Application.find(123), "Application-123") }.to raise_error('connection failed')
  end

  it "will succeed for an instance connection if the connection policy does support instances" do
    ApplicationPolicy.always_allow_connection
    ApplicationPolicy.regulate_instance_connections { self }
    expect { Synchromesh::InternalPolicy.regulate_connection(Application.find(123), "Application-123") }.not_to raise_error
  end

  it "will succeed only if the user id is correct" do
    ApplicationPolicy.regulate_instance_connections { Application.find('baz') }
    expect { Synchromesh::InternalPolicy.regulate_connection(nil, "Application-baz") }.not_to raise_error
  end

  it "can be applied to a different class" do
    stub_const "Class1", Class.new(Application)
    stub_const "Class2", Class.new(Application)
    ApplicationPolicy.regulate_instance_connections(Class1, Class2) { self }
    expect { Synchromesh::InternalPolicy.regulate_connection(Class1.find('baz'), "Class1-baz") }.not_to raise_error
    expect { Synchromesh::InternalPolicy.regulate_connection(Class2.find('baz'), "Class2-baz") }.not_to raise_error
    expect { Synchromesh::InternalPolicy.regulate_connection(Application.find('baz'), "Application-baz") }.to raise_error('connection failed')
  end

end
