module Hyperstack
  module Legacy
    module Store
      class InvalidOptionError < StandardError; end
      class InvalidOperationError < StandardError; end
      class << self
        def included(base)
          base.include(Hyperstack::Internal::Store::InstanceMethods)
          base.extend(Hyperstack::Internal::Store::ClassMethods)
          base.extend(Hyperstack::Internal::Store::DispatchReceiver)

          base.singleton_class.define_singleton_method(:__state_wrapper) do
            @__state_wrapper ||= Class.new(Hyperstack::Internal::Store::StateWrapper)
          end

          base.singleton_class.define_singleton_method(:state) do |*args, &block|
            __state_wrapper.define_state_methods(base, *args, &block)
          end
        end
      end
    end
  end
end
