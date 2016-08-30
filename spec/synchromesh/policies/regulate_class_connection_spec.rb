require 'spec_helper'
#require 'synchromesh/test_components'

describe "regulate class connections" do

  before(:each) do
    stub_const "ApplicationPolicy", Class.new
  end

  it "will fail if there is no connection policy for a class" do
    ApplicationPolicy.regulate_instance_connections { self }
    expect { Synchromesh::InternalPolicy.regulate_connection(nil, "Application") }.to raise_error('connection failed')
  end

  it "will succeed if there is a connection policy for a class" do
    ApplicationPolicy.regulate_class_connection { true }
    expect { Synchromesh::InternalPolicy.regulate_connection(nil, "Application") }.not_to raise_error
  end

  it "the class connection policy ignores the acting_user object" do
    ApplicationPolicy.regulate_class_connection { true }
    expect { Synchromesh::InternalPolicy.regulate_connection("acting_user", "Application") }.not_to raise_error
  end

  it "can be applied to a different class" do
    stub_const "Class1", Class.new
    stub_const "Class2", Class.new
    ApplicationPolicy.regulate_class_connection(Class1, Class2) { true }
    expect { Synchromesh::InternalPolicy.regulate_connection(nil, "Class1") }.not_to raise_error
    expect { Synchromesh::InternalPolicy.regulate_connection(nil, "Class2") }.not_to raise_error
    expect { Synchromesh::InternalPolicy.regulate_connection(nil, "Application") }.to raise_error('connection failed')
  end

  it "can be simplified using the always_allow_connection method" do
    ApplicationPolicy.always_allow_connection
    expect { Synchromesh::InternalPolicy.regulate_connection(nil, "Application") }.not_to raise_error
  end

  it "can conditionally regulate the connection" do
    ApplicationPolicy.regulate_class_connection { self }
    expect { Synchromesh::InternalPolicy.regulate_connection(true, "Application") }.not_to raise_error
    expect { Synchromesh::InternalPolicy.regulate_connection(nil, "Application") }.to raise_error('connection failed')
  end

  it "can conditionally regulate the connection by raising an error" do
    ApplicationPolicy.regulate_class_connection { raise "POW" unless self=="okay"; true }
    expect { Synchromesh::InternalPolicy.regulate_connection("okay", "Application") }.not_to raise_error
    expect { Synchromesh::InternalPolicy.regulate_connection("dokey", "Application") }.to raise_error('connection failed')
  end

end
