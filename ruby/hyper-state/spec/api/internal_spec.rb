require 'spec_helper'

describe Hyperstack::Internal::State::Mapper do

  context 'observe, observed!, mutated! and update_states_to_observe' do

    it "will notify the observers when an observed objects are mutated" do
      # each observer would typically be a react component.
      observer1 = double('observer1')
      observer2 = double('observer2')
      object1 = double('object1')
      object2 = double('object2')
      object3 = double('object3')


      allow(Hyperstack).to receive(:on_client?) { true }

      expect(observer1).to receive(:mutations).once.with([object1, object2])
      expect(observer2).to receive(:mutations).once.with([object1, object3])

      # observer 1  reads a state
      Hyperstack::Internal::State::Mapper.observe(observer1, false, false) do
        Hyperstack::Internal::State::Mapper.observed!(object1)
        Hyperstack::Internal::State::Mapper.observed!(object2)
        Hyperstack::Internal::State::Mapper.update_objects_to_observe
      end

      Hyperstack::Internal::State::Mapper.mutated!(object1)
      Hyperstack::Internal::State::Mapper.mutated!(object2)
      Hyperstack::Internal::State::Mapper.mutated!(object3)
      # simulate the JS event completion.  run_after is
      Hyperstack::Internal::State::Mapper.run_after

      # now components will rerender.  This time observer1 calls
      # update_states_to_observe without reading the state thus clearing it
      # from the list of observers
      # but observer2 does read the state
      Hyperstack::Internal::State::Mapper.update_objects_to_observe(observer1)
      Hyperstack::Internal::State::Mapper.observe(observer2, false, false) do
        Hyperstack::Internal::State::Mapper.observed!(object1)
        Hyperstack::Internal::State::Mapper.observed!(object3)
        Hyperstack::Internal::State::Mapper.update_objects_to_observe
      end

      # so now observer2 will be notified by not observer1
      Hyperstack::Internal::State::Mapper.mutated!(object1)
      Hyperstack::Internal::State::Mapper.mutated!(object2)
      Hyperstack::Internal::State::Mapper.mutated!(object3)
      Hyperstack::Internal::State::Mapper.run_after
    end

    it "on the server observers are notified immediately" do
      # each observer would typically be a react component.
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

      # observer 1  reads a state
      Hyperstack::Internal::State::Mapper.observe(observer1, false, false) do
        Hyperstack::Internal::State::Mapper.observed!(object1)
        Hyperstack::Internal::State::Mapper.observed!(object2)
        Hyperstack::Internal::State::Mapper.update_objects_to_observe
      end

      Hyperstack::Internal::State::Mapper.mutated!(object1)
      Hyperstack::Internal::State::Mapper.mutated!(object2)
      Hyperstack::Internal::State::Mapper.mutated!(object3)

      Hyperstack::Internal::State::Mapper.update_objects_to_observe(observer1)
      Hyperstack::Internal::State::Mapper.observe(observer2, false, false) do
        Hyperstack::Internal::State::Mapper.observed!(object1)
        Hyperstack::Internal::State::Mapper.observed!(object3)
        Hyperstack::Internal::State::Mapper.update_objects_to_observe
      end

      # so now observer2 will be notified by not observer1
      Hyperstack::Internal::State::Mapper.mutated!(object1)
      Hyperstack::Internal::State::Mapper.mutated!(object2)
      Hyperstack::Internal::State::Mapper.mutated!(object3)
    end

    it "the bulk update flag can override the on_client status" do
      # each observer would typically be a react component.
      observer1 = double('observer1')
      observer2 = double('observer2')
      object1 = double('object1')
      object2 = double('object2')
      object3 = double('object3')


      allow(Hyperstack).to receive(:on_client?) { false }

      expect(observer1).to receive(:mutations).once.with([object1, object2])
      expect(observer2).to receive(:mutations).once.with([object1, object3])

      # observer 1  reads a state
      Hyperstack::Internal::State::Mapper.observe(observer1, false, false) do
        Hyperstack::Internal::State::Mapper.observed!(object1)
        Hyperstack::Internal::State::Mapper.observed!(object2)
        Hyperstack::Internal::State::Mapper.update_objects_to_observe
      end
      Hyperstack::Internal::State::Mapper.bulk_update do
        Hyperstack::Internal::State::Mapper.mutated!(object1)
        Hyperstack::Internal::State::Mapper.mutated!(object2)
        Hyperstack::Internal::State::Mapper.mutated!(object3)
      end
      # simulate the JS event completion.  run_after is
      Hyperstack::Internal::State::Mapper.run_after

      # now components will rerender.  This time observer1 calls
      # update_states_to_observe without reading the state thus clearing it
      # from the list of observers
      # but observer2 does read the state
      Hyperstack::Internal::State::Mapper.update_objects_to_observe(observer1)
      Hyperstack::Internal::State::Mapper.observe(observer2, false, false) do
        Hyperstack::Internal::State::Mapper.observed!(object1)
        Hyperstack::Internal::State::Mapper.observed!(object3)
        Hyperstack::Internal::State::Mapper.update_objects_to_observe
      end

      # so now observer2 will be notified by not observer1
      Hyperstack::Internal::State::Mapper.bulk_update do
        Hyperstack::Internal::State::Mapper.mutated!(object1)
        Hyperstack::Internal::State::Mapper.mutated!(object2)
        Hyperstack::Internal::State::Mapper.mutated!(object3)
      end
      Hyperstack::Internal::State::Mapper.run_after
    end

    it "special case immediate notification if observer requests it" do
      # each observer would typically be a react component.
      observer1 = double('observer1')
      observer2 = double('observer2')
      object = double('object')
      allow(Hyperstack).to receive(:on_client?) { true }

      expect(observer1).to receive(:mutations).twice.with([observer1])
      expect(observer2).to receive(:mutations).twice.with([observer1])

      # both observers see the state change
      Hyperstack::Internal::State::Mapper.observe(observer1, false, false) do
        Hyperstack::Internal::State::Mapper.observed!(observer1)
        Hyperstack::Internal::State::Mapper.observed!(observer2)
        Hyperstack::Internal::State::Mapper.update_objects_to_observe
      end
      Hyperstack::Internal::State::Mapper.observe(observer2, false, false) do
        Hyperstack::Internal::State::Mapper.observed!(observer1)
        Hyperstack::Internal::State::Mapper.observed!(observer2)
        Hyperstack::Internal::State::Mapper.update_objects_to_observe
      end
      Hyperstack::Internal::State::Mapper.observe(observer1, true, false) do
        Hyperstack::Internal::State::Mapper.mutated!(observer1)
        Hyperstack::Internal::State::Mapper.mutated!(observer2)
        Hyperstack::Internal::State::Mapper.observe(observer1, true, true) do
          Hyperstack::Internal::State::Mapper.mutated!(observer1)
          Hyperstack::Internal::State::Mapper.mutated!(observer2)
        end
        Hyperstack::Internal::State::Mapper.observe(observer1, true, false) do
          Hyperstack::Internal::State::Mapper.mutated!(observer1)
          Hyperstack::Internal::State::Mapper.mutated!(observer2)
        end
      end
    end
    it "has an observed? method" do
      # each observer would typically be a react component.
      observer1 = double('observer1')
      object1 = double('object1')
      object2 = double('object2')

      # observer 1  reads a state
      Hyperstack::Internal::State::Mapper.observe(observer1, false, false) do
        Hyperstack::Internal::State::Mapper.observed!(object1)
        Hyperstack::Internal::State::Mapper.update_objects_to_observe
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
      Hyperstack::Internal::State::Mapper.observe(observer1, false, false) do
        Hyperstack::Internal::State::Mapper.observed!(object1)
        Hyperstack::Internal::State::Mapper.update_objects_to_observe
      end
      Hyperstack::Internal::State::Mapper.observe(observer2, false, false) do
        Hyperstack::Internal::State::Mapper.observed!(object1)
        Hyperstack::Internal::State::Mapper.update_objects_to_observe
      end
      Hyperstack::Internal::State::Mapper.observe(observer1, false, false) do
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
      Hyperstack::Internal::State::Mapper.observe(observer1, false, false) do
        Hyperstack::Internal::State::Mapper.observed!(object1)
        Hyperstack::Internal::State::Mapper.update_objects_to_observe
      end
      Hyperstack::Internal::State::Mapper.observe(observer2, false, false) do
        Hyperstack::Internal::State::Mapper.observed!(object1)
        Hyperstack::Internal::State::Mapper.update_objects_to_observe
      end
      Hyperstack::Internal::State::Mapper.mutated!(object1)
      Hyperstack::Internal::State::Mapper.observe(observer1, false, false) do
        Hyperstack::Internal::State::Mapper.observed!(object1)
      end
      Hyperstack::Internal::State::Mapper.run_after
    end

  end
end
