module HyperStore
  class StateWrapper < BaseStoreClass
    extend ArgumentValidator

    class << self
      attr_reader :instance_state_wrapper, :class_state_wrapper,
                  :instance_mutator_wrapper, :class_mutator_wrapper,
                  :wrappers

      def inherited(subclass)
        subclass.add_class_instance_vars(subclass) if self == StateWrapper
      end

      def add_class_instance_vars(subclass)
        @shared_state_wrapper     = subclass
        @instance_state_wrapper   = Class.new(@shared_state_wrapper)
        @class_state_wrapper      = Class.new(@shared_state_wrapper)

        @shared_mutator_wrapper   = Class.new(MutatorWrapper)
        @instance_mutator_wrapper = Class.new(@shared_mutator_wrapper)
        @class_mutator_wrapper    = Class.new(@shared_mutator_wrapper)

        @wrappers = [@instance_state_wrapper, @instance_mutator_wrapper,
                     @class_state_wrapper, @class_mutator_wrapper]
      end

      def define_state_methods(klass, *args, &block)
        return self if args.empty?

        name, opts = validate_args!(klass, *args, &block)

        add_readers(klass, name, opts)
        klass.singleton_class.state.add_error_methods(name, opts)
        klass.singleton_class.state.add_methods(klass, name, opts)
        klass.singleton_class.state.remove_methods(name, opts)
        klass.send(:"__#{opts[:scope]}_states") << [name, opts]
      end

      def add_readers(klass, name, opts)
        return unless opts[:reader]

        if [:instance, :shared].include?(opts[:scope])
          klass.class_eval do
            define_method(:"#{opts[:reader]}") { state.__send__(:"#{name}") }
          end
        end

        if [:class, :shared].include?(opts[:scope])
          klass.define_singleton_method(:"#{opts[:reader]}") { state.__send__(:"#{name}") }
        end
      end

      def add_error_methods(name, opts)
        return if opts[:scope] == :shared

        [@shared_state_wrapper, @shared_mutator_wrapper].each do |klass|
          klass.define_singleton_method(:"#{name}") do
            'nope!'
          end
        end
      end

      def add_methods(klass, name, opts)
        instance_variable_get("@#{opts[:scope]}_state_wrapper").add_method(klass, name, opts)
        instance_variable_get("@#{opts[:scope]}_mutator_wrapper").add_method(klass, name, opts)
      end

      def add_method(klass, method_name, opts = {})
        define_method(:"#{method_name}") do
          from = opts[:scope] == :shared ? klass.state.__from__ : @__from__
          React::State.get_state(from, method_name.to_s)
        end
      end

      def remove_methods(name, opts)
        return unless opts[:scope] == :shared

        wrappers.each do |wrapper|
          wrapper.send(:remove_method, :"#{name}") if wrapper.respond_to?(:"#{name}")
        end
      end

      def default_scope(klass)
        if self == klass.singleton_class.__state_wrapper.class_state_wrapper
          :instance
        else
          :class
        end
      end
    end

    attr_accessor :__from__

    def self.new(from)
      instance = allocate
      instance.__from__ = from
      instance
    end

    # Any method_missing call will create a state and accessor with that name
    def method_missing(name, *args, &block) # rubocop:disable Style/MethodMissing
      $method_missing = [name, *args]
      (class << self; self end).add_method(nil, name) #(class << self; self end).superclass.add_method(nil, name)
      __send__(name, *args, &block)
    end
  end
end
