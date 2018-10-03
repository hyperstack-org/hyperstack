require 'spec_helper'

# Just checks to make sure all methods are available when either subclassing or including
describe Hyperstack::Internal::State::ClassMethods do
  before(:each) do
  end

  context 'low level get and set state API' do

    it "will notify the observer when the state is set" do
      # each observer would typically be a react component.
      observer1 = double('observer1')
      observer2 = double('observer2')

      expect(observer1).to receive(:update_react_js_state).once.with(:obj, "state1", "updated")
      expect(observer2).to receive(:update_react_js_state).once

      # observer 1  reads a state which by default will be nil.
      val = ""
      Hyperstack::Internal::State.set_state_context_to(observer1) do
        val = Hyperstack::Internal::State.get_state(:obj, "state1")
        Hyperstack::Internal::State.update_states_to_observe
      end
      expect(val).to be_nil

      # because its observing it should be notified when the state is set
      # the "true" param just forces the code to run using JS after method even
      # though we are on the server.  See spec_helper for why this works.
      Hyperstack::Internal::State.set_state(:obj, "state1", "updated", true)
      # simulate the JS after call.
      Hyperstack::Internal::State.run_after

      # now components will rerender.  This time observer1 calls
      # update_states_to_observe without reading the state thus clearing it
      # from the list of observers
      # but observer2 does read the state
      Hyperstack::Internal::State.update_states_to_observe(observer1)
      Hyperstack::Internal::State.set_state_context_to(observer2) do
        val = Hyperstack::Internal::State.get_state(:obj, "state1")
        Hyperstack::Internal::State.update_states_to_observe
      end
      expect(val).to eq("updated")

      # so now observer2 will be notified by not observer1
      Hyperstack::Internal::State.set_state(:obj, "state1", "updated again", true)
      Hyperstack::Internal::State.run_after

      # final check that the state was updated
      val = Hyperstack::Internal::State.get_state(:obj, "state1", observer1)
      expect(val).to eq("updated again")
    end
  end
end
