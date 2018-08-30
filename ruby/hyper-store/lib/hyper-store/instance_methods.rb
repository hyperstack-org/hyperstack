module HyperStore
  module InstanceMethods
    def init_store
      self.class.__instance_states.each do |instance_state|
        # If the scope is shared then we initialize at the class level
        next if instance_state[1][:scope] == :shared

        # TODO: Figure out exactly how we're going to handle passing in procs and blocks together
        # But for now...just do the proc first then the block

        # First initialize value from initializer Proc
        proc_value = initializer_value(instance_state[1][:initializer])
        mutate.__send__(:"#{instance_state[0]}", proc_value)

        # Then call the block if a block is passed
        next unless instance_state[1][:block]

        block_value = instance_eval(&instance_state[1][:block])
        mutate.__send__(:"#{instance_state[0]}", block_value)
      end

    end

    def state
      @state ||= self.class.singleton_class.__state_wrapper.instance_state_wrapper.new(self)
    end

    def mutate
      @mutate ||= self.class.singleton_class.__state_wrapper.instance_mutator_wrapper.new(self)
    end

    private

    def initializer_value(initializer)
      # We gotta check the arity because a Proc passed in directly from initializer has no args,
      # but if we created one then we might have wanted self
      initializer.arity > 0 ? initializer.call(self) : initializer.call
    end
  end
end
