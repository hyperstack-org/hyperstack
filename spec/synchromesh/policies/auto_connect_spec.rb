require 'spec_helper'

describe 'channel auto connect' do

  it 'will autoconnect' do
    stub_const "ApplicationPolicy", Class.new
    ApplicationPolicy.regulate_connection { true }
    expect(Synchromesh::AutoConnect.channels(nil)).to eq(["Application"])
  end

  it 'will autoconnect to multiple channels' do
    stub_const 'ApplicationPolicy', Class.new
    ApplicationPolicy.regulate_connection { true }
    ApplicationPolicy.regulate_connection('AnotherChannel') { true }
    expect(Synchromesh::AutoConnect.channels(nil)).to eq(['Application', 'AnotherChannel'])
  end

  it 'will not autoconnect if disabled' do
    stub_const 'ApplicationPolicy', Class.new
    ApplicationPolicy.disable_auto_connect
    ApplicationPolicy.regulate_connection { true }
    ApplicationPolicy.regulate_connection('AnotherChannel') { true }
    expect(Synchromesh::AutoConnect.channels(nil)).to eq(['AnotherChannel'])
  end

  it 'can autoconnect to an instance' do
    stub_const 'ApplicationPolicy', Class.new
    acting_user = "UserInstance"
    acting_user.define_singleton_method(:id) { 1 }
    ApplicationPolicy.regulate_connection { |acting_user, id| id && acting_user.id == 1 }
    expect(Synchromesh::AutoConnect.channels(acting_user)).to eq([['Application', 1]])
  end

  it 'can override the id method' do
    stub_const 'ApplicationPolicy', Class.new
    acting_user = "UserInstance"
    ApplicationPolicy.auto_connect { |acting_user| acting_user.object_id }
    ApplicationPolicy.regulate_connection { |acting_user, id| acting_user.object_id == id }
    expect(Synchromesh::AutoConnect.channels(acting_user)).to eq([['Application', acting_user.object_id]])
  end

  it 'can autoconnect to an instance and class' do
    stub_const 'ApplicationPolicy', Class.new
    acting_user = "UserInstance"
    acting_user.define_singleton_method(:id) { 1 }
    ApplicationPolicy.regulate_connection { |acting_user, id| id.nil? || acting_user.id == 1 }
    expect(Synchromesh::AutoConnect.channels(acting_user)).to eq(['Application', ['Application', 1]])
  end
end
