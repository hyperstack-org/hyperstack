module HyperStore
  module ClassMethods
    attr_accessor :__shared_states, :__class_states, :__instance_states

    def state(*args, &block)
      # If we're passing in any arguments then we are calling the macro to define a state
      if args.count > 0
        singleton_class.__state_wrapper.class_state_wrapper
                       .define_state_methods(self, *args, &block)
      # Otherwise we are just accessing it
      else
        @state ||= singleton_class.__state_wrapper.class_state_wrapper.new(self)
      end
    end

    def mutate
      @mutate ||= singleton_class.__state_wrapper.class_mutator_wrapper.new(self)
    end

    def __shared_states
      @__shared_states ||= []
    end

    def __class_states
      @__class_states ||= []
    end

    def __instance_states
      @__instance_states ||= []
    end
  end
end
