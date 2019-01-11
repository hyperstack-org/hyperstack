module Hyperstack
  module Internal
    module Component
      class RescueMetaWrapper
        include Hyperstack::Component

        param :children_elements

        render do
          @ChildrenElements.call
        end
      end

      class RescueWrapper
        class << self
          attr_accessor :after_error_args
        end

        include Hyperstack::Component

        param :child
        param :children_elements

        render do
          RescueMetaWrapper(children_elements: @ChildrenElements)
        end

        after_error do |error, info|
          args = RescueWrapper.after_error_args || [error, info]
          found, * = @Child.run_callback(:__hyperstack_component_rescue_hook, found, *args) { |a| a }
          unless found
            RescueWrapper.after_error_args = args
            raise error
          end
          @Child.force_update!
        end
      end
    end
  end
end
