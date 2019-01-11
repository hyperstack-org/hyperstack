module Hyperstack
  module Internal
    module Component
      class WhileLoadingWrapper < RescueWrapper
        render do
          if @waiting_on_resources && !quiet?
            RenderingContext.raise_if_not_quiet = false
          else
            @waiting_on_resources = false
            @Child.instance_eval do
              mutate if @__hyperstack_while_loading_waiting_on_resources
              @__hyperstack_while_loading_waiting_on_resources = false
            end
            RenderingContext.raise_if_not_quiet = true
          end
          RescueMetaWrapper(children_elements: @ChildrenElements)
        end

        before_mount do
          wrapper = self
          @Child.class.rescues RenderingContext::NotQuiet do
            wrapper.instance_variable_set(:@waiting_on_resources, true)
            @__hyperstack_while_loading_waiting_on_resources = true
          end
        end
      end
    end
  end
end
