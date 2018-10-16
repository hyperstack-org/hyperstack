module Hyperstack
  module State
    module Observable
      class InvalidOptionError < StandardError; end

      def self.bulk_update(&block)
        Internal::State::Mapper.bulk_update(&block)
      end

      def self.included(base)
        { instance: base, class: base.singleton_class }.each do |type, receiver|
          receiver.define_singleton_method(:state) do |*args, &block|
            Internal::State::Wrapper.define_state_methods(self, type, *args, &block)
          end
        end

        Internal::State::Wrapper.define_wrapper_methods(base)
      end
    end
  end
end
