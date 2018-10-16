require 'spec_helper'

describe Hyperstack::Internal::State::Mapper do
  it "will notify the observers when an observed objects are mutated" do
    observer1 = double('observer1')
    observer2 = double('observer2')
    object1 = double('object1')
    object2 = double('object2')
    object3 = double('object3')

    allow(Hyperstack).to receive(:on_client?) { true }

    expect(observer1).to receive(:mutations).once.with([object1, object2])
    expect(observer2).to receive(:mutations).once.with([object1, object3])

    Hyperstack::Internal::State::Mapper.observing(observer1, false, false, false) do
      Hyperstack::Internal::State::Mapper.observed!(object1)
      Hyperstack::Internal::State::Mapper.observed!(object2)
      Hyperstack::Internal::State::Mapper.update_objects_to_observe
    end

    Hyperstack::Internal::State::Mapper.mutated!(object1)
    Hyperstack::Internal::State::Mapper.mutated!(object2)
    Hyperstack::Internal::State::Mapper.mutated!(object3)
    # simulate the JS event completion.  run_after is
    Hyperstack::Internal::State::Mapper.run_after

    Hyperstack::Internal::State::Mapper.update_objects_to_observe(observer1)
    Hyperstack::Internal::State::Mapper.observing(observer2, false, false, false) do
      Hyperstack::Internal::State::Mapper.observed!(object1)
      Hyperstack::Internal::State::Mapper.observed!(object3)
      Hyperstack::Internal::State::Mapper.update_objects_to_observe(observer2)
    end

    Hyperstack::Internal::State::Mapper.mutated!(object1)
    Hyperstack::Internal::State::Mapper.mutated!(object2)
    Hyperstack::Internal::State::Mapper.mutated!(object3)
    Hyperstack::Internal::State::Mapper.run_after
  end

  it "update_objects_to_observe can be run automatically" do
    observer1 = double('observer1')

    allow(Hyperstack).to receive(:on_client?) { true }

    expect(Hyperstack::Internal::State::Mapper)
    .to receive(:update_objects_to_observe).once.with(observer1)

    Hyperstack::Internal::State::Mapper.observing(observer1, false, false, true) {}
  end

  it "an observer always observes itself and its class" do
    observer1 = double('observer1')

    allow(Hyperstack).to receive(:on_client?) { true }

    expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).once.with(observer1)
    expect(Hyperstack::Internal::State::Mapper).to receive(:observed!).once.with(observer1.class)

    Hyperstack::Internal::State::Mapper.observing(observer1, false, false, true) {}
  end

  it "an observer is only recorded once" do
    observer1 = double('observer1')
    object1 = double('object1')

    allow(Hyperstack).to receive(:on_client?) { true }

    expect(observer1).to receive(:mutations).once.with([object1])

    Hyperstack::Internal::State::Mapper.observing(observer1, false, false, true) do
      Hyperstack::Internal::State::Mapper.observed!(object1)
      Hyperstack::Internal::State::Mapper.observed!(object1)
    end

    Hyperstack::Internal::State::Mapper.mutated!(object1)
    # simulate the JS event completion.  run_after is
    Hyperstack::Internal::State::Mapper.run_after
  end

  it "on the server observers are notified immediately" do
    observer1 = double('observer1')
    observer2 = double('observer2')
    object1 = double('object1')
    object2 = double('object2')
    object3 = double('object3')

    allow(Hyperstack).to receive(:on_client?) { false }

    expect(observer1).to receive(:mutations).once.with([object1])
    expect(observer1).to receive(:mutations).once.with([object2])
    expect(observer2).to receive(:mutations).once.with([object1])
    expect(observer2).to receive(:mutations).once.with([object3])

    Hyperstack::Internal::State::Mapper.observing(observer1, false, false, true) do
      Hyperstack::Internal::State::Mapper.observed!(object1)
      Hyperstack::Internal::State::Mapper.observed!(object2)
    end

    Hyperstack::Internal::State::Mapper.mutated!(object1)
    Hyperstack::Internal::State::Mapper.mutated!(object2)
    Hyperstack::Internal::State::Mapper.mutated!(object3)

    Hyperstack::Internal::State::Mapper.update_objects_to_observe(observer1)
    Hyperstack::Internal::State::Mapper.observing(observer2, false, false, true) do
      Hyperstack::Internal::State::Mapper.observed!(object1)
      Hyperstack::Internal::State::Mapper.observed!(object3)
    end

    Hyperstack::Internal::State::Mapper.mutated!(object1)
    Hyperstack::Internal::State::Mapper.mutated!(object2)
    Hyperstack::Internal::State::Mapper.mutated!(object3)
  end

  it "the bulk update flag can override the on_client status" do
    observer1 = double('observer1')
    observer2 = double('observer2')
    object1 = double('object1')
    object2 = double('object2')
    object3 = double('object3')

    allow(Hyperstack).to receive(:on_client?) { false }

    expect(observer1).to receive(:mutations).once.with([object1, object2])
    expect(observer2).to receive(:mutations).once.with([object1, object3])

    Hyperstack::Internal::State::Mapper.observing(observer1, false, false, true) do
      Hyperstack::Internal::State::Mapper.observed!(object1)
      Hyperstack::Internal::State::Mapper.observed!(object2)
    end
    Hyperstack::Internal::State::Mapper.bulk_update do
      Hyperstack::Internal::State::Mapper.mutated!(object1)
      Hyperstack::Internal::State::Mapper.mutated!(object2)
      Hyperstack::Internal::State::Mapper.mutated!(object3)
    end
    Hyperstack::Internal::State::Mapper.run_after

    Hyperstack::Internal::State::Mapper.update_objects_to_observe(observer1)
    Hyperstack::Internal::State::Mapper.observing(observer2, false, false, true) do
      Hyperstack::Internal::State::Mapper.observed!(object1)
      Hyperstack::Internal::State::Mapper.observed!(object3)
    end

    Hyperstack::Internal::State::Mapper.bulk_update do
      Hyperstack::Internal::State::Mapper.mutated!(object1)
      Hyperstack::Internal::State::Mapper.mutated!(object2)
      Hyperstack::Internal::State::Mapper.mutated!(object3)
    end
    Hyperstack::Internal::State::Mapper.run_after
  end

  it "special case immediate notification if observer requests it" do
    observer1 = double('observer1')
    observer2 = double('observer2')
    allow(Hyperstack).to receive(:on_client?) { true }

    expect(observer1).to receive(:mutations).twice.with([observer1])
    expect(observer2).to receive(:mutations).twice.with([observer1])

    Hyperstack::Internal::State::Mapper.observing(observer1, false, false, true) do
      Hyperstack::Internal::State::Mapper.observed!(observer2)
    end
    Hyperstack::Internal::State::Mapper.observing(observer2, false, false, true) do
      Hyperstack::Internal::State::Mapper.observed!(observer1)
    end

    Hyperstack::Internal::State::Mapper.observing(observer1, true, false, false) do
      Hyperstack::Internal::State::Mapper.mutated!(observer1)
      Hyperstack::Internal::State::Mapper.mutated!(observer2)
      Hyperstack::Internal::State::Mapper.observing(observer1, true, true, false) do
        Hyperstack::Internal::State::Mapper.mutated!(observer1)
        Hyperstack::Internal::State::Mapper.mutated!(observer2)
      end
      Hyperstack::Internal::State::Mapper.observing(observer1, true, false, false) do
        Hyperstack::Internal::State::Mapper.mutated!(observer1)
        Hyperstack::Internal::State::Mapper.mutated!(observer2)
      end
    end
  end

  it "has an observed? method" do
    observer1 = double('observer1')
    object1 = double('object1')
    object2 = double('object2')

    Hyperstack::Internal::State::Mapper.observing(observer1, false, false, true) do
      Hyperstack::Internal::State::Mapper.observed!(object1)
    end
    expect(Hyperstack::Internal::State::Mapper.observed?(object1)).to be_truthy
    expect(Hyperstack::Internal::State::Mapper.observed?(object2)).to be_falsy
  end

  it "has a remove method" do
    observer1 = double('observer1')
    observer2 = double('observer2')
    object1 = double('object1')
    allow(Hyperstack).to receive(:on_client?) { true }

    expect(observer1).not_to receive(:mutations)
    expect(observer2).to receive(:mutations).once.with([object1])
    Hyperstack::Internal::State::Mapper.observing(observer1, false, false, true) do
      Hyperstack::Internal::State::Mapper.observed!(object1)
    end
    Hyperstack::Internal::State::Mapper.observing(observer2, false, false, true) do
      Hyperstack::Internal::State::Mapper.observed!(object1)
    end
    Hyperstack::Internal::State::Mapper.observing(observer1, false, false, false) do
      Hyperstack::Internal::State::Mapper.observed!(object1)
      Hyperstack::Internal::State::Mapper.remove
    end
    Hyperstack::Internal::State::Mapper.mutated!(object1)
    Hyperstack::Internal::State::Mapper.run_after
  end

  it "will exclude observers that have observed an object after mutation" do
    observer1 = double('observer1')
    observer2 = double('observer2')
    object1 = double('object1')
    allow(Hyperstack).to receive(:on_client?) { true }

    expect(observer1).not_to receive(:mutations)
    expect(observer2).to receive(:mutations).once.with([object1])
    Hyperstack::Internal::State::Mapper.observing(observer1, false, false, true) do
      Hyperstack::Internal::State::Mapper.observed!(object1)
    end
    Hyperstack::Internal::State::Mapper.observing(observer2, false, false, true) do
      Hyperstack::Internal::State::Mapper.observed!(object1)
    end
    Hyperstack::Internal::State::Mapper.mutated!(object1)
    Hyperstack::Internal::State::Mapper.observing(observer1, false, false, false) do
      Hyperstack::Internal::State::Mapper.observed!(object1)
    end
    Hyperstack::Internal::State::Mapper.run_after
  end
end
