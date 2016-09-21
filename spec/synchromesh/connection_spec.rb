require 'spec_helper'

describe Synchromesh::Connection do

  before(:each) do
    Timecop.return
  end

  it 'adding new connection' do
    described_class.new('TestChannel', 0)
    expect(described_class.active).to eq(['TestChannel'])
  end

  it 'new connections expire' do
    described_class.new('TestChannel', 0)
    expect(described_class.active).to eq(['TestChannel'])
    Timecop.travel(Time.now+described_class.transport.expire_new_connection_in)
    expect(described_class.active).to eq([])
  end

  it 'can send and read data from a channel' do
    described_class.new('TestChannel', 0)
    described_class.new('TestChannel', 1)
    described_class.new('AnotherChannel', 0)
    described_class.send('TestChannel', 'data')
    expect(described_class.read(0)).to eq(['data'])
    expect(described_class.read(0)).to eq([])
    expect(described_class.read(1)).to eq(['data'])
    expect(described_class.read(1)).to eq([])
    expect(described_class.read(0)).to eq([])
  end

  it 'will update the expiration time after reading' do
    described_class.new('TestChannel', 0)
    described_class.send('TestChannel', 'data')
    described_class.read(0)
    Timecop.travel(Time.now+described_class.transport.expire_new_connection_in)
    expect(described_class.active).to eq(['TestChannel'])
  end

  it 'will expire a polled connection' do
    described_class.new('TestChannel', 0)
    described_class.send('TestChannel', 'data')
    described_class.read(0)
    Timecop.travel(Time.now+described_class.transport.expire_polled_connection_in)
    expect(described_class.active).to eq([])
  end

  context 'after connecting to the transport' do
    before(:each) do
      described_class.new('TestChannel', 0)
      described_class.new('TestChannel', 1)
      described_class.send('TestChannel', 'data')
    end

    it "will pass any pending data back" do
      expect(described_class.connect_to_transport('TestChannel', 0, nil)).to eq(['data'])
    end

    it "will have the root path set for console access" do
      described_class.connect_to_transport('TestChannel', 0, "some_path")
      expect(Synchromesh::Connection.root_path).to eq("some_path")
    end

    it "the channel will still be active even after initial connection time is expired" do
      described_class.connect_to_transport('TestChannel', 0, nil)
      Timecop.travel(Time.now+described_class.transport.expire_new_connection_in)
      expect(described_class.active).to eq(['TestChannel'])
    end

    it "will only effect the session being connected" do
      described_class.connect_to_transport('TestChannel', 0, nil)
      expect(described_class.read(1)).to eq(['data'])
    end

    it "will begin refreshing the channel list" do
      allow(Synchromesh).to receive(:refresh_channels) {sleep 0.2; ['AnotherChannel']}
      described_class.new('AnotherChannel', 0)
      described_class.connect_to_transport('TestChannel', 0, nil)
      described_class.connect_to_transport('AnotherChannel', 0, nil)
      expect(described_class.active).to eq(['TestChannel', 'AnotherChannel'])
      Timecop.travel(Time.now+described_class.transport.refresh_channels_every)
      described_class.active
      sleep(0.5)
      expect(described_class.active).to eq(['AnotherChannel'])
    end

    it "refreshing will not effect channels not connected to the transport" do
      allow(Synchromesh).to receive(:refresh_channels) {sleep 0.2; ['AnotherChannel']}
      described_class.new('AnotherChannel', 0)
      described_class.connect_to_transport('TestChannel', 0, nil)
      Timecop.travel(Time.now+described_class.transport.refresh_channels_every-1)
      described_class.read(1)
      described_class.connect_to_transport('AnotherChannel', 0, nil)
      expect(described_class.active).to eq(['TestChannel', 'AnotherChannel'])
      Timecop.travel(Time.now+1)
      described_class.active
      sleep(0.5)
      expect(described_class.active).to eq(['TestChannel', 'AnotherChannel'])
    end

    it "refreshing will not effect channels recently added" do
      allow(Synchromesh).to receive(:refresh_channels) {sleep 0.2; ['AnotherChannel']}
      described_class.new('AnotherChannel', 0)
      described_class.connect_to_transport('TestChannel', 0, nil)
      Timecop.travel(Time.now+described_class.transport.refresh_channels_every)
      described_class.connect_to_transport('AnotherChannel', 0, nil)
      expect(described_class.active).to eq(['TestChannel', 'AnotherChannel'])
      described_class.new('TestChannel', 2)
      sleep(0.5)
      expect(described_class.active).to eq(['AnotherChannel', 'TestChannel'])
    end

    it "sends messages to the transport as well as open channels" do
      expect(Synchromesh).to receive(:send).with('TestChannel', 'data2')
      described_class.connect_to_transport('TestChannel', 0, nil)
      described_class.send('TestChannel', 'data2')
      expect(described_class.read(1)).to eq(['data', 'data2'])
    end
  end
end
