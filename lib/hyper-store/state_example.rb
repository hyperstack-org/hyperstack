class State
  class << self
    def inherited(subclass)
      return unless self == State
      @shared_proxy = subclass
      @instance_proxy = Class.new(@shared_proxy)
      @class_proxy = Class.new(@shared_proxy)
      @shared_mutator_proxy = Class.new(Mutator)
      @instance_mutator_proxy = Class.new(@shared_mutator_proxy)
      @class_mutator_proxy = Class.new(@shared_mutator_proxy)
    end

    attr_reader :instance_proxy
    attr_reader :class_proxy
    attr_reader :instance_mutator_proxy
    attr_reader :class_mutator_proxy

    def define_accessor(*args, &block)
      # process args into name, opts, and init_value
      # call add_error_methods / add_method / remove_method
    end

    def add_error_methods name
      [@shared_proxy, @shared_mutator_proxy].each do |klass|
        klass.define_method(name) do |*args, &block|
          "illegal boss"
        end
      end
    end

    def add_method(name, opts = {}, init_value, &block)
      define_method(name) do ...
      end
    end

    def default_scope
      self == @instance_proxy ? :instance : :class
    end
  end

  def method_missing(name, *args, &block)
    self.class.add_method name
    self.send(name, *args, &block)
  end

end

class Mutator
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
      @state ||= Class.new(State).new
      @state.class.define_accessor(*args, &block)
      @state
    end
  end

  def self.state(*args, &block)
    @state ||= singleton_class.state.class.class_proxy.new
    singleton_class.state.class.class_proxy.process_args(*args, &block)
    @state
  end

  def self.mutate
    @mutate ||= singleton_class.state.class.class_mutator_proxy.new
  end

  def state
    @state ||= self.class.singleton_class.state.class.instance_proxy.new
  end

  def mutate
    @mutate ||= self.class.singleton_class.state.class.instance_mutator_proxy.new
  end

end
