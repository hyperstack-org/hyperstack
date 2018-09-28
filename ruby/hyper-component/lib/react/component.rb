require 'react/ext/string'
require 'react/ext/hash'
require 'active_support/core_ext/class/attribute'
require 'react/callbacks'
require 'react/rendering_context'
require 'hyper-store'
require 'react/state_wrapper'
require 'react/component/api'
require 'react/component/class_methods'
require 'react/component/props_wrapper'
module WhackyStack
end
module Hyperstack
  module Component

    # TODO: move to its own file (i.e. component/force_update)
    module Internal
      class << self
        def mounted_components
          @mounted_components ||= Set.new
        end
      end
    end
    def self.force_update!
      components = Internal.mounted_components.to_a
      components.each do |comp|
        next unless Internal.mounted_components.include? comp
        comp.force_update!
      end
    end
    # end of todo

    module Mixin
      def self.included(base)
        base.include(Hyperstack::Store::Mixin)
        base.include(Internal::InstanceMethods)
        base.include(Internal::Callbacks)
        base.include(Internal::Tags)
        #base.include(React::Component::DslInstanceMethods)
        base.include(Internal::ShouldComponentUpdate)
        base.class_eval do
          class_attribute :initial_state
          define_callback :before_mount
          define_callback :after_mount
          define_callback :before_receive_props
          define_callback :before_update
          define_callback :after_update
          define_callback :before_unmount
          define_callback(:after_error) { Internal::ReactWrapper.add_after_error_hook(base) }
        end
        base.extend(Internal::ClassMethods)
      end

      def self.deprecation_warning(message)
        Hyperstack.deprecation_warning(name, message)
      end

      def deprecation_warning(message)
        Hyperstack.deprecation_warning(self.class.name, message)
      end

      def initialize(native_element)
        @native = native_element
        init_store
      end

      def emit(event_name, *args)
        if Event::BUILT_IN_EVENTS.include?(built_in_event_name = "on#{event_name.to_s.event_camelize}")
          params[built_in_event_name].call(*args)
        else
          params["on_#{event_name}"].call(*args)
        end
      end

      def component_will_mount
        IsomorphicHelpers.load_context(true) if IsomorphicHelpers.on_opal_client?
        Store::Internal::State.set_state_context_to(self) do
          Internal.mounted_components << self
          run_callback(:before_mount)
        end
      end

      def component_did_mount
        Store::Internal::State.set_state_context_to(self) do
          run_callback(:after_mount)
          Store::Internal::State.update_states_to_observe
        end
      end

      def component_will_receive_props(next_props)
        # need to rethink how this works in opal-react, or if its actually that useful within the react.rb environment
        # for now we are just using it to clear processed_params
        Store::Internal::State.set_state_context_to(self) { run_callback(:before_receive_props, next_props) }
        @_receiving_props = true
      end

      def component_will_update(next_props, next_state)
        Store::Internal::State.set_state_context_to(self) { run_callback(:before_update, next_props, next_state) }
        params._reset_all_others_cache if @_receiving_props
        @_receiving_props = false
      end

      def component_did_update(prev_props, prev_state)
        Store::Internal::State.set_state_context_to(self) do
          run_callback(:after_update, prev_props, prev_state)
          Store::Internal::State.update_states_to_observe
        end
      end

      def component_will_unmount
        Store::Internal::State.set_state_context_to(self) do
          run_callback(:before_unmount)
          Store::Internal::State.remove
          Internal.mounted_components.delete self
        end
      end

      def component_did_catch(error, info)
        Store::Internal::State.set_state_context_to(self) do
          run_callback(:after_error, error, info)
        end
      end

      attr_reader :waiting_on_resources

      def update_react_js_state(object, name, value)
        if object
          name = "#{object.class}.#{name}" unless object == self
          # Date.now() has only millisecond precision, if several notifications of
          # observer happen within a millisecond, updates may get lost.
          # to mitigate this the Math.random() appends some random number
          # this way notifactions will happen as expected by the rest of hyperloop
          set_state(
            '***_state_updated_at-***' => `Date.now() + Math.random()`,
            name => value
          )
        else
          set_state name => value
        end
      end

      def set_state_synchronously?
        @native.JS[:__opalInstanceSyncSetState]
      end

      def render
        raise 'no render defined'
      end unless method_defined?(:render)

      def _render_wrapper
        Store::Internal::State.set_state_context_to(self, true) do
          element = Internal::RenderingContext.render(nil) { render || '' }
          @waiting_on_resources =
            element.waiting_on_resources if element.respond_to? :waiting_on_resources
          element
        end
      end

      def watch(value, &on_change)
        Store::Observable.new(value, on_change)
      end

      def define_state(*args, &block)
        Store::Internal::State.initialize_states(self, self.class.define_state(*args, &block))
      end
    end
  end
end

# module React
#   module Component
#     def self.included(base)
#       # note this is turned off during old style testing:  See the spec_helper
#       deprecation_warning base, "The module name React::Component has been deprecated.  Use Hyperloop::Component::Mixin instead."
#       base.include Hyperloop::Component::Mixin
#     end
#     def self.deprecation_warning(name, message)
#       @deprecation_messages ||= []
#       message = "Warning: Deprecated feature used in #{name}. #{message}"
#       unless @deprecation_messages.include? message
#         @deprecation_messages << message
#         React::IsomorphicHelpers.log message, :warning
#       end
#     end
#   end
#   module ComponentNoNotice
#     def self.included(base)
#       base.include Hyperloop::Component::Mixin
#     end
#   end
# end
#
# module React
# end
