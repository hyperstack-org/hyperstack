module Hyperstack
  module Component
    module WhileLoading
      def __hyperstack_component_rescue_wrapper(child)
        Hyperstack::Internal::Component::WhileLoadingWrapper(child: self, children_elements: child)
      end

      def resources_loading?
        @__hyperstack_while_loading_waiting_on_resources
      end

      def resources_loaded?
        !@__hyperstack_while_loading_waiting_on_resources
      end

      if Hyperstack::Component::IsomorphicHelpers.on_opal_client?
        %x{
          function onError(event) {
            if (event.message.match(/^Uncaught NotQuiet: /)) event.preventDefault();
          }

          window.addEventListener('error', onError);
         }
      end
    end
  end
end
