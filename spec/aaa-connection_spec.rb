require 'spec_helper'

describe Hyperloop::Connection do

  before(:all) do
    Hyperloop.configuration do |config|
    end
  end

  before(:each) do
    Timecop.return
  end

  it 'creates the tables' do
    ActiveRecord::Base.connection.data_sources.should include('hyperloop_connections')
    ActiveRecord::Base.connection.data_sources.should include('hyperloop_queued_messages')
    described_class.column_names.should =~ ['id', 'channel', 'session', 'created_at', 'expires_at', 'refresh_at']
  end

  it 'creates the messages queue' do
    channel = described_class.new
    channel.messages << Hyperloop::Connection::QueuedMessage.new
    channel.save
    channel.reload
    channel.messages.should eq(Hyperloop::Connection::QueuedMessage.all)
  end

  it 'can set the root path' do
    described_class.root_path = 'foobar'
    expect(described_class.root_path).to eq('foobar')
  end

  it 'adding new connection' do
    described_class.open('TestChannel', 0)
    expect(described_class.active).to eq(['TestChannel'])
  end

  it 'new connections expire' do
    described_class.open('TestChannel', 0)
    expect(described_class.active).to eq(['TestChannel'])
    Timecop.travel(Time.now+described_class.transport.expire_new_connection_in)
    expect(described_class.active).to eq([])
  end

  it 'can send and read data from a channel' do
    described_class.open('TestChannel', 0)
    described_class.open('TestChannel', 1)
    described_class.open('AnotherChannel', 0)
    described_class.send_to_channel('TestChannel', 'data')
    expect(described_class.read(0, 'path')).to eq(['data'])
    expect(described_class.read(0, 'path')).to eq([])
    expect(described_class.read(1, 'path')).to eq(['data'])
    expect(described_class.read(1, 'path')).to eq([])
    expect(described_class.read(0, 'path')).to eq([])
  end

  it 'will update the expiration time after reading' do
    described_class.open('TestChannel', 0)
    described_class.send_to_channel('TestChannel', 'data')
    described_class.read(0, 'path')
    Timecop.travel(Time.now+described_class.transport.expire_new_connection_in)
    expect(described_class.active).to eq(['TestChannel'])
  end

  it 'will expire a polled connection' do
    described_class.open('TestChannel', 0)
    described_class.send_to_channel('TestChannel', 'data')
    described_class.read(0, 'path')
    Timecop.travel(Time.now+described_class.transport.expire_polled_connection_in)
    expect(described_class.active).to eq([])
  end

  context 'after connecting to the transport' do
    before(:each) do
      described_class.open('TestChannel', 0)
      described_class.open('TestChannel', 1)
      described_class.send_to_channel('TestChannel', 'data')
    end

    it "will pass any pending data back" do
      expect(described_class.connect_to_transport('TestChannel', 0, nil)).to eq(['data'])
    end

    it "will have the root path set for console access" do
      described_class.connect_to_transport('TestChannel', 0, "some_path")
      expect(Hyperloop::Connection.root_path).to eq("some_path")
    end

    it "the channel will still be active even after initial connection time is expired" do
      described_class.connect_to_transport('TestChannel', 0, nil)
      Timecop.travel(Time.now+described_class.transport.expire_new_connection_in)
      expect(described_class.active).to eq(['TestChannel'])
    end

    it "will only effect the session being connected" do
      described_class.connect_to_transport('TestChannel', 0, nil)
      expect(described_class.read(1, 'path')).to eq(['data'])
    end

    it "will begin refreshing the channel list" do
      allow(Hyperloop).to receive(:refresh_channels) {['AnotherChannel']}
      described_class.open('AnotherChannel', 0)
      described_class.connect_to_transport('TestChannel', 0, nil)
      described_class.connect_to_transport('AnotherChannel', 0, nil)
      expect(described_class.active).to eq(['TestChannel', 'AnotherChannel'])
      Timecop.travel(Time.now+described_class.transport.refresh_channels_every)
      expect(described_class.active).to eq(['AnotherChannel'])
    end

    it "refreshing will not effect channels not connected to the transport" do
      allow(Hyperloop).to receive(:refresh_channels) {['AnotherChannel']}
      described_class.open('AnotherChannel', 0)
      described_class.connect_to_transport('TestChannel', 0, nil)
      Timecop.travel(Time.now+described_class.transport.refresh_channels_every-1)
      described_class.read(1, 'path')
      described_class.connect_to_transport('AnotherChannel', 0, nil)
      expect(described_class.active).to eq(['TestChannel', 'AnotherChannel'])
      Timecop.travel(Time.now+1)
      described_class.active
      expect(described_class.active).to eq(['TestChannel', 'AnotherChannel'])
    end

    it "refreshing will not effect channels added during the refresh" do
      allow(Hyperloop).to receive(:refresh_channels) do
        described_class.connect_to_transport('TestChannel', 0, nil)
        ['AnotherChannel']
      end
      described_class.open('AnotherChannel', 0)
      Timecop.travel(Time.now+described_class.transport.refresh_channels_every)
      described_class.read(0, 'path')
      described_class.connect_to_transport('AnotherChannel', 0, nil)
      expect(described_class.active).to eq(['TestChannel', 'AnotherChannel'])
      described_class.open('TestChannel', 2)
      expect(described_class.active).to eq(['TestChannel', 'AnotherChannel'])
    end

    it "sends messages to the transport as well as open channels" do
      expect(Hyperloop).to receive(:send_data).with('TestChannel', 'data2')
      described_class.connect_to_transport('TestChannel', 0, nil)
      described_class.send_to_channel('TestChannel', 'data2')
      expect(described_class.read(1, 'path')).to eq(['data', 'data2'])
    end
  end
end
