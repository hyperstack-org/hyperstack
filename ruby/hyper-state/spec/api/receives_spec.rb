require 'spec_helper'

describe 'receives method' do
  class Store
    include Hyperstack::State::Observable
  end
  let(:store) { Store.new }

  it 'the store can pass a block to the receives method and will be called back' do
    broadcaster = double('Broadcaster')
    proc = -> (data) { store.proc_called(data) }
    expect(store).to receive(:proc_called).with([1, 2, 3])
    allow(broadcaster).to receive(:on_dispatch) { |&block| block.call([1, 2, 3])}
    store.receives(broadcaster, &proc)
  end

  it 'the store can pass proc to the receives method and will be called back' do
    broadcaster = double('Broadcaster')
    proc = -> (data) { store.proc_called(data) }
    expect(store).to receive(:proc_called).with([1, 2, 3])
    allow(broadcaster).to receive(:on_dispatch) { |&block| block.call([1, 2, 3])}
    store.receives(broadcaster, proc)
  end

  it 'the store can pass a method name to the receives method and will be called back' do
    broadcaster = double('Broadcaster')
    expect(store).to receive(:proc_called).with([1, 2, 3])
    allow(broadcaster).to receive(:on_dispatch) { |&block| block.call([1, 2, 3])}
    store.receives(broadcaster, :proc_called)
  end

  it 'will receive from and close broadcast channels with the receives method' do
    broadcaster = double('Broadcaster')
    expect(broadcaster).to receive(:on_dispatch).and_return(broadcaster)
    store.receives(broadcaster)
    expect(broadcaster).to receive(:unmount)
    store.unmount
  end

  it "will ignore calls to the receives method once unmounted" do
    broadcaster = double('Broadcaster')
    store.unmount
    expect(broadcaster).not_to receive(:on_dispatch)
    store.receives(broadcaster)
  end
end
