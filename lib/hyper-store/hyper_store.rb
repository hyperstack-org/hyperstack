module HyperStore
  class << self
    def included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)

      base.singleton_class.define_singleton_method(:__state_wrapper) do
        @__state_wrapper ||= Class.new(StateWrapper)
      end

      base.singleton_class.define_singleton_method(:state) do |*args, &block|
        __state_wrapper.define_state_methods(base, *args, &block)
      end
    end
  end
end
