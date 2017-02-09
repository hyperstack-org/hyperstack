class StateWrapper
  class << self
    def inherited(subclass)
      subclass.add_class_instance_vars if self == StateWrapper
    end

    def add_class_instance_vars
      @shared_state_wrapper = subclass
      @instance_state_wrapper = Class.new(@shared_wrapper)
      @class_state_wrapper = Class.new(@shared_wrapper)
      @shared_mutator_wrapper = Class.new(Mutator)
      @instance_mutator_wrapper = Class.new(@shared_mutator_wrapper)
      @class_mutator_wrapper = Class.new(@shared_mutator_wrapper)
      @wrappers = [
        @instance_state_wrapper, @instance_mutator_wrapper,
        @class_state_wrapper, @class_mutator_wrapper
      ]

    end

    attr_reader :instance_state_wrapper
    attr_reader :class_state_wrapper
    attr_reader :instance_mutator_wrapper
    attr_reader :class_mutator_wrapper
    attr_reader :wrappers

    def define_state_methods(klass, *args, &block)
      return self if args.empty?
      opts = process_args(klass, *args)
      add_readers(klass, opts)
      add_error_methods(opts)
      add_methods(opts)
      remove_methods(opts)
    end

    def process_args(klass, *args, &block)
      # returns *args processed into opts, will add name key, and will update initialize key
      # and the scope
      # so that initialize is always a proc or nil... that part if fun
      # (state_name: some_value...) ==+> (name: :state_name, initialize: -> () { some_value.dup })
      # (state_name, ... initialize: :meth_name) ===> (name: :state_name, initialize: klass-depends-on-scope.method(:meth_name))
      # (state_name, ... initialize: someproc) ===> (name: :state_name, initialize: someproc)
      # (state_name, ... &block) ===> (name: :state_name, initialize: block)
      # (state_name ....) ===> (name: :state_name, ... no initialize key ...)
    end

    def add_readers(klass, opts)
      if opts[:scope] == :instance
        klass.define_method(opts[:reader]) { state.send(opts[:name]) }  ## we could get it directly from React::State...
      else
        klass.singleton_class.define_method(...) I think???
      end unless opts[:reader]
    end

    def add_error_methods(opts)
      [@shared_state_wrapper, @shared_mutator_wrapper].each do |klass|
        klass.define_method(opts[:name]) do |*args, &block|
          "illegal boss"
        end
      end unless opts[:scope] == :shared
    end

    def add_methods(opts)
      instance_variable_get("@#{opts[:scope]}_state_wrapper").add_method opts[:name], opts[:initialize], opts[:reader]
      instance_variable_get("@#{opts[:scope]}_mutator_wrapper").add_method opts[:name]
    end

    def remove_methods(opts)
      wrappers.each { |wrapper| wrapper.remove_method opts[:name] } if opts[:scope] == :shared
    end

    def add_method(klass, opts)
      # define the method
      define_method(opts[:name]) do ...
      end

      return unless opts[:initializer]
    end

    def default_scope
      # remember:
      # class Store
      #   state :foo # this is calling the state wrapper but defining instance variables
      #   class << self
      #     state :foo # this is calling the shared state wrapper but defining class variables
      #   end
      # end
      self == @class_state_wrapper ? :instance : :class
    end
  end

  def method_missing(name, *args, &block)
    self.class.add_method name
    self.send(name, *args, &block)
  end

end

class MutatorWrapper
  def method_missing(name, *args, &block)
    self.class.add_method name
    self.send(name, *args, &block)
  end

  def self.add_method(name)
    def define_method(name) do ...
    end
  end
end

class HyperStore::Base
  def self.inherited(child)
    child.singleton_class.define_singleton_method(:state) do |*args, &block|
      # the singleton_class_method is only called either to define states
      # or for the class and instance methods to get the wrapper so we just
      # save the wrapper.  We don't need an instance here.
      @state_wrapper ||= Class.new(StateWrapper)
      @state_wrapper.define_state_methods(child, *args, &block) # i think this is self here
    end
  end

  def self.state(*args, &block)
    singleton_class.state.class_state_wrapper.define_state_methods(child, *args, &block)
    @state ||= singleton_class.state.class_state_wrapper.new
  end

  def self.mutate
    @mutate ||= singleton_class.state.class_mutator_wrapper.new
  end

  def state
    @state ||= self.class.singleton_class.instance_state_wrapper.new
  end

  def mutate
    @mutate ||= self.class.singleton_class.instance_mutator_wrapper.new
  end
end
