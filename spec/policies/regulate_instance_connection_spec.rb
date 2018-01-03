require 'spec_helper'

describe "regulate_instance_connections" do

  before(:each) do
    stub_const "TestApplicationPolicy", Class.new
    class TestApplication < ActiveRecord::Base
      def self.columns
        @columns ||= [];
      end
      def self.column(name, sql_type = nil, default = nil, null = true)
        columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default,
          sql_type.to_s, null)
      end
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
      def self.attribute_types
        { id: Integer }
      end
      def self.attribute_names
        @attributes ||= attribute_types.keys
      end
    end
  end

  it "will fail for an instance connection if the connection policy does not support instances" do
    TestApplicationPolicy.always_allow_connection
    expect { Hyperloop::InternalPolicy.regulate_connection(TestApplication.find(123), "TestApplication-123") }.to raise_error('connection failed')
  end

  it "will succeed for an instance connection if the connection policy does support instances" do
    TestApplicationPolicy.always_allow_connection
    TestApplicationPolicy.regulate_instance_connections { self }
    expect { Hyperloop::InternalPolicy.regulate_connection(TestApplication.find(123), "TestApplication-123") }.not_to raise_error
  end

  it "will succeed only if the user id is correct" do
    TestApplicationPolicy.regulate_instance_connections { TestApplication.find('baz') }
    expect { Hyperloop::InternalPolicy.regulate_connection(nil, "TestApplication-baz") }.not_to raise_error
  end

  it "can be applied to a different class" do
    stub_const "Class1", Class.new(TestApplication)
    stub_const "Class2", Class.new(TestApplication)
    TestApplicationPolicy.regulate_instance_connections(Class1, Class2) { self }
    expect { Hyperloop::InternalPolicy.regulate_connection(Class1.find('baz'), "Class1-baz") }.not_to raise_error
    expect { Hyperloop::InternalPolicy.regulate_connection(Class2.find('baz-2'), "Class2-baz-2") }.not_to raise_error
    expect { Hyperloop::InternalPolicy.regulate_connection(TestApplication.find('baz'), "TestApplication-baz") }.to raise_error('connection failed')
  end

  it "can return an array objects" do
    TestApplicationPolicy.regulate_instance_connections { [TestApplication.find(1), TestApplication.find(2)] }
    expect { Hyperloop::InternalPolicy.regulate_connection("foo", "TestApplication-1") }.not_to raise_error
    expect { Hyperloop::InternalPolicy.regulate_connection("foo", "TestApplication-2") }.not_to raise_error
  end

  it "can conditionally regulate the connection" do
    TestApplicationPolicy.regulate_instance_connections { id == '1' && self }
    expect { Hyperloop::InternalPolicy.regulate_connection(TestApplication.new(1), "TestApplication-1") }.not_to raise_error
    expect { Hyperloop::InternalPolicy.regulate_connection(TestApplication.new(2), "TestApplication-2") }.to raise_error('connection failed')
  end

  it "can regulate the connection by raising an error" do
    TestApplicationPolicy.regulate_instance_connections { raise "POW" unless id == '1'; self}
    expect { Hyperloop::InternalPolicy.regulate_connection(TestApplication.new(1), "TestApplication-1") }.not_to raise_error
    expect { Hyperloop::InternalPolicy.regulate_connection(TestApplication.new(2), "TestApplication-2") }.to raise_error('connection failed')
  end
end
