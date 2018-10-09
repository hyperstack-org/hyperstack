module Hyperstack
  module State

    class InvalidOptionError < StandardError; end

    # instance state cache

    # def __hyperstack_states
    #   @__hyperstack_states ||= {}
    # end

    def self.included(base)

      # instance state definition macro

      base.define_singleton_method(:state) do |*args, &block|
        Internal::State::Wrapper.define_state_methods(self, :instance, *args, &block)
      end

      # class state cache

      # base.define_singleton_method(:__hyperstack_states) do
      #   Hyperstack::Context.set_var(base, :@__hyperstack_states) { Hash.new { |h, k| h[k] = {} } }
      # end

      # class state definition macro

      base.singleton_class.define_singleton_method(:state) do |*args, &block|
        Internal::State::Wrapper.define_state_methods(self, :class, *args, &block)
      end
    end
  end
end
