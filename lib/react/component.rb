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
require 'native'

module Hyperloop
  class Component
    module Mixin
      def self.included(base)
        base.include(Hyperloop::Store::Mixin)
        base.include(React::Component::API)
        base.include(React::Callbacks)
        base.include(React::Component::Tags)
        base.include(React::Component::DslInstanceMethods)
        base.include(React::Component::ShouldComponentUpdate)
        base.class_eval do
          class_attribute :initial_state
          define_callback :before_mount
          define_callback :after_mount
          define_callback :before_receive_props
          define_callback :before_update
          define_callback :after_update
          define_callback :before_unmount
          define_callback :after_error
        end
        base.extend(React::Component::ClassMethods)
      end

      def self.deprecation_warning(message)
        React::Component.deprecation_warning(name, message)
      end

      def deprecation_warning(message)
        React::Component.deprecation_warning(self.class.name, message)
      end

      def initialize(native_element)
        @native = native_element
        init_store
      end

      def emit(event_name, *args)
        if React::Event::BUILT_IN_EVENTS.include?(built_in_event_name = "on#{event_name.to_s.event_camelize}")
          params[built_in_event_name].call(*args)
        else
          params["on_#{event_name}"].call(*args)
        end
      end

      def component_will_mount
        React::IsomorphicHelpers.load_context(true) if React::IsomorphicHelpers.on_opal_client?
        React::State.set_state_context_to(self) { run_callback(:before_mount) }
      end

      def component_did_mount
        React::State.set_state_context_to(self) do
          run_callback(:after_mount)
          React::State.update_states_to_observe
        end
      end

      def component_will_receive_props(next_props)
        # need to rethink how this works in opal-react, or if its actually that useful within the react.rb environment
        # for now we are just using it to clear processed_params
        React::State.set_state_context_to(self) { self.run_callback(:before_receive_props, next_props) }
      end

      def component_will_update(next_props, next_state)
        React::State.set_state_context_to(self) { self.run_callback(:before_update, next_props, next_state) }
      end

      def component_did_update(prev_props, prev_state)
        React::State.set_state_context_to(self) do
          self.run_callback(:after_update, prev_props, prev_state)
          React::State.update_states_to_observe
        end
      end

      def component_will_unmount
        React::State.set_state_context_to(self) do
          self.run_callback(:before_unmount)
          React::State.remove
        end
      end

      def component_did_catch(error, info)
        React::State.set_state_context_to(self) do
          if self.class.callbacks_for(:after_error) == []
            if `typeof error.$backtrace === "function"`
              `console.error(error.$backtrace().$join("\n"))`
            else
              `console.error(error, info)`
            end
          else
            self.run_callback(:after_error, error, info)
          end
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
        React::State.set_state_context_to(self, true) do
          element = React::RenderingContext.render(nil) { render || '' }
          @waiting_on_resources =
            element.waiting_on_resources if element.respond_to? :waiting_on_resources
          element
        end
      end

      def watch(value, &on_change)
        Observable.new(value, on_change)
      end

      def define_state(*args, &block)
        React::State.initialize_states(self, self.class.define_state(*args, &block))
      end
    end
  end
end

module React
  module Component
    def self.included(base)
      # note this is turned off during old style testing:  See the spec_helper
      deprecation_warning base, "The module name React::Component has been deprecated.  Use Hyperloop::Component::Mixin instead."
      base.include Hyperloop::Component::Mixin
    end
    def self.deprecation_warning(name, message)
      @deprecation_messages ||= []
      message = "Warning: Deprecated feature used in #{name}. #{message}"
      unless @deprecation_messages.include? message
        @deprecation_messages << message
        React::IsomorphicHelpers.log message, :warning
      end
    end
  end
  module ComponentNoNotice
    def self.included(base)
      base.include Hyperloop::Component::Mixin
    end
  end
end

module React
end
