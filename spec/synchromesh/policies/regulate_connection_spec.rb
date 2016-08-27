require 'spec_helper'
#require 'synchromesh/test_components'

describe "regulate_connection" do

  before(:all) do
  end

  it "will fail if there is no connection policy for a class" do
    stub_const "ApplicationPolicy", Class.new
    expect { Synchromesh::InternalPolicy.regulate_connection(nil, "Application") }.to raise_error('connection failed')
  end

  it "will succeed if there is a connection policy for a class" do
    stub_const "ApplicationPolicy", Class.new
    ApplicationPolicy.regulate_connection { true }
    expect { Synchromesh::InternalPolicy.regulate_connection(nil, "Application") }.not_to raise_error
  end

  it "will fail for an instance connection if the connection policy does not support instances" do
    stub_const "ApplicationPolicy", Class.new
    ApplicationPolicy.regulate_connection { true }
    expect { Synchromesh::InternalPolicy.regulate_connection(nil, "Application-123") }.to raise_error('connection failed')
  end

  it "will succeed for an instance connection if the connection policy does support instances" do
    stub_const "ApplicationPolicy", Class.new
    ApplicationPolicy.regulate_connection { |user, id| id==123 }
    expect { Synchromesh::InternalPolicy.regulate_connection(nil, "Application-123") }.not_to raise_error
  end

  it "will succeed for an channel connection if the connection policy does support instances" do
    stub_const "ApplicationPolicy", Class.new
    ApplicationPolicy.regulate_connection { |user, id| !id }
    expect { Synchromesh::InternalPolicy.regulate_connection(nil, "Application") }.not_to raise_error
  end

  it "supports non integer instance ids" do
    stub_const "ApplicationPolicy", Class.new
    ApplicationPolicy.regulate_connection { |user, id| id=="baz" }
    expect { Synchromesh::InternalPolicy.regulate_connection(nil, "Application-baz") }.not_to raise_error
  end

  it "passes the user-id to the policy" do
    stub_const "ApplicationPolicy", Class.new
    ApplicationPolicy.regulate_connection { |user, id| user=="human" }
    expect { Synchromesh::InternalPolicy.regulate_connection("human", "Application-baz") }.not_to raise_error
  end

  it "can be used multiple times" do
    stub_const "ApplicationPolicy", Class.new
    ApplicationPolicy.regulate_connection { |user, id| user=="human" }
    ApplicationPolicy.regulate_connection { |user, id| id==123 }
    ApplicationPolicy.regulate_connection { |user| user=="dog" }
    expect { Synchromesh::InternalPolicy.regulate_connection("human", "Application-123") }.not_to raise_error
    expect { Synchromesh::InternalPolicy.regulate_connection("dog", "Application") }.not_to raise_error
    expect { Synchromesh::InternalPolicy.regulate_connection("human", "Application") }.to raise_error('connection failed')
    expect { Synchromesh::InternalPolicy.regulate_connection("dog", "Application-123") }.to raise_error('connection failed')
  end

  it "can be applied to a different class" do
    stub_const "ApplicationPolicy", Class.new
    stub_const "Class1", Class.new
    stub_const "Class2", Class.new
    ApplicationPolicy.regulate_connection(Class1, Class2) { |user, id| user=="human" && id=="baz" }
    expect { Synchromesh::InternalPolicy.regulate_connection("human", "Class1-baz") }.not_to raise_error
    expect { Synchromesh::InternalPolicy.regulate_connection("human", "Class2-baz") }.not_to raise_error
    expect { Synchromesh::InternalPolicy.regulate_connection("human", "Application-baz") }.to raise_error('connection failed')
  end

end
