require 'react/ext/string'
require 'react/ext/hash'
require 'active_support/core_ext/class/attribute'
require 'react/callbacks'
require 'react/rendering_context'
require 'react/observable'
require 'react/state'
require 'react/component/api'
require 'react/component/class_methods'
require 'react/component/props_wrapper'
require 'native'

module React
  module Component
    def self.included(base)
      base.include(API)
      base.include(Callbacks)
      base.include(Tags)
      base.include(DslInstanceMethods)
      base.include(ShouldComponentUpdate)
      base.class_eval do
        class_attribute :initial_state
        define_callback :before_mount
        define_callback :after_mount
        define_callback :before_receive_props
        define_callback :before_update
        define_callback :after_update
        define_callback :before_unmount
      end
      base.extend(ClassMethods)
    end

    def self.deprecation_warning(message)
      @deprecation_messages ||= []
      message = "Warning: Deprecated feature used in #{name}. #{message}"
      unless @deprecation_messages.include? message
        @deprecation_messages << message
        IsomorphicHelpers.log message, :warning
      end
    end

    def initialize(native_element)
      @native = native_element
    end

    def emit(event_name, *args)
      params["_on#{event_name.to_s.event_camelize}"].call(*args)
    end

    def component_will_mount
      IsomorphicHelpers.load_context(true) if IsomorphicHelpers.on_opal_client?
      set_state! initial_state if initial_state
      State.initialize_states(self, initial_state)
      State.set_state_context_to(self) { run_callback(:before_mount) }
    rescue Exception => e
      self.class.process_exception(e, self)
    end

    def component_did_mount
      State.set_state_context_to(self) do
        run_callback(:after_mount)
        State.update_states_to_observe
      end
    rescue Exception => e
      self.class.process_exception(e, self)
    end

    def component_will_receive_props(next_props)
      # need to rethink how this works in opal-react, or if its actually that useful within the react.rb environment
      # for now we are just using it to clear processed_params
      State.set_state_context_to(self) { self.run_callback(:before_receive_props, Hash.new(next_props)) }
    rescue Exception => e
      self.class.process_exception(e, self)
    end

    def component_will_update(next_props, next_state)
      State.set_state_context_to(self) { self.run_callback(:before_update, Hash.new(next_props), Hash.new(next_state)) }
    rescue Exception => e
      self.class.process_exception(e, self)
    end

    def component_did_update(prev_props, prev_state)
      State.set_state_context_to(self) do
        self.run_callback(:after_update, Hash.new(prev_props), Hash.new(prev_state))
        State.update_states_to_observe
      end
    rescue Exception => e
      self.class.process_exception(e, self)
    end

    def component_will_unmount
      State.set_state_context_to(self) do
        self.run_callback(:before_unmount)
        State.remove
      end
    rescue Exception => e
      self.class.process_exception(e, self)
    end

    attr_reader :waiting_on_resources

    def update_react_js_state(object, name, value)
      if object
        name = "#{object.class}.#{name}" unless object == self
        set_state(
          '***_state_updated_at-***' => Time.now.to_f,
          name => value
        )
      else
        set_state name => value
      end
    end

    def render
      raise 'no render defined'
    end unless method_defined?(:render)

    def _render_wrapper
      State.set_state_context_to(self, true) do
        element = React::RenderingContext.render(nil) { render || '' }
        @waiting_on_resources =
          element.waiting_on_resources if element.respond_to? :waiting_on_resources
        element
      end
    # rubocop:disable Lint/RescueException # we want to catch all exceptions regardless
    rescue Exception => e
      # rubocop:enable Lint/RescueException
      self.class.process_exception(e, self)
    end

    def watch(value, &on_change)
      Observable.new(value, on_change)
    end

    def define_state(*args, &block)
      State.initialize_states(self, self.class.define_state(*args, &block))
    end
  end
end
