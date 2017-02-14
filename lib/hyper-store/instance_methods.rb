module HyperStore
  module InstanceMethods
    def initialize
      self.class.__instance_states.each do |instance_state|
        next if instance_state[1][:scope] == :shared
        # TODO: Figure out exactly how we're going to handle passing in procs and blocks together
        # But for now...

        # First initialize value from initialize Proc

        # If the initialize argument was passed in as a symbol,
        # we need to pass in the instance to the proc
        # Otherwise we do not pass in anything
        proc_value =
          if instance_state[1][:initialize].parameters &&
             instance_state[1][:initialize].parameters.any?
            instance_state[1][:initialize].call(self)
          else
            instance_state[1][:initialize].call
          end

        mutate.send(:"#{instance_state[0]}", proc_value)

        # Then call the block if a block is passed
        next unless instance_state[1][:block]

        block_value = instance_eval(&instance_state[1][:block])
        mutate.send(:"#{instance_state[0]}", block_value)
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
