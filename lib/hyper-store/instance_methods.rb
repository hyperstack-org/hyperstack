module HyperStore
  module InstanceMethods
    def initialize
      self.class.__instance_states.each do |instance_state|
        # First initialize value from initialize Proc
        mutate.send(:"#{instance_state[0]}", instance_state[1][:initialize].call(self))

        # Then call the block if a block is passed
        instance_eval(&instance_state[1][:block]) if instance_state[1][:block]
      end

      super
    end

    def state
      @state ||= self.class.singleton_class.__state_wrapper.instance_state_wrapper.new(self)
    end

    def mutate
      @mutate ||= self.class.singleton_class.__state_wrapper.instance_mutator_wrapper.new(self)
    end
  end
end
