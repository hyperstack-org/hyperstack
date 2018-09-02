module Hyperloop
  class Store
    module Mixin
      class << self
        def included(base)
          base.include(HyperStore::InstanceMethods)
          base.extend(HyperStore::ClassMethods)
          base.extend(HyperStore::DispatchReceiver)

          base.singleton_class.define_singleton_method(:__state_wrapper) do
            @__state_wrapper ||= Class.new(HyperStore::StateWrapper)
          end

          base.singleton_class.define_singleton_method(:state) do |*args, &block|
            __state_wrapper.define_state_methods(base, *args, &block)
          end
        end
      end
    end
  end
end
