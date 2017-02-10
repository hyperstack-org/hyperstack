module HyperStore
  module ClassMethods
    attr_accessor :__shared_states, :__class_states, :__instance_states

    def receives(*args, &block)
      callback = [Symbol, Proc].include?(args.last.class) ? args.pop : nil

      if args.last.is_a?(Symbol)
        puts "our callback is a method!"
      elsif args.last.is_a?(Proc)
        puts "our callback is a proc!"
      end

      puts "our callback is a block!" if block


      puts "Calling ClassMethods#receieves: #{args}"
    end

    def state(*args, &block)
      if args.count > 0
        singleton_class.__state_wrapper.class_state_wrapper
                       .define_state_methods(self, *args, &block)
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
