require 'hyperstack/ext/component/string'

module Hyperstack
  module Component
    #
    # Wraps the React Native element class
    #
    # adds the #on method to add event handlers to the element
    #
    # adds the #render method to place elements in the DOM and
    # #delete (alias/deprecated #as_node) method to remove elements from the DOM
    #
    # handles the haml style class notation so that
    #  div.bar.blat becomes div(class: "bar blat")
    # by using method missing
    #
    class Element
      include Native

      alias_native :element_type, :type
      alias_native :props, :props

      attr_reader :type
      attr_reader :properties
      attr_reader :block

      attr_accessor :waiting_on_resources

      def initialize(native_element, type = nil, properties = {}, block = nil)
        @type = type
        @properties = (`typeof #{properties} === 'undefined'` ? nil : properties) || {}
        @block = block
        @native = native_element
      end

      def _update_ref(x)
        @ref = x
        @_child_element._update_ref(x) if @_child_element
      end

      def ref
        return @ref if @ref
        raise("The instance of #{self.type} has not been mounted yet") if properties[:ref]
        raise("Attempt to get a ref on #{self.type} which is a static component.")
      end

      def dom_node
        `typeof #{ref}.$dom_node == 'function'` ? ref.dom_node : ref
      end

      # Attach event handlers. skip false, nil and blank event names

      def on(*event_names, &block)
        any_found = false
        event_names.each do |event_name|
          next unless event_name && event_name.strip != ''
          merge_event_prop!(event_name, &block)
          any_found = true
        end
        @native = `React.cloneElement(#{@native}, #{@properties.shallow_to_n})` if any_found
        self
      end

      # Render element into DOM in the current rendering context.
      # Used for elements that are not yet in DOM, i.e. they are provided as children
      # or they have been explicitly removed from the rendering context using the delete method.

      def render(*props)
        if props.empty?
          Hyperstack::Internal::Component::RenderingContext.render(self)
        else
          props = Hyperstack::Internal::Component::ReactWrapper.convert_props(@type, @properties, *props)
          @_child_element = Hyperstack::Internal::Component::RenderingContext.render(
            Element.new(`React.cloneElement(#{@native}, #{props.shallow_to_n})`,
                        type, props, block)
          )
        end
      end

      # Delete (remove) element from rendering context, the element may later be added back in
      # using the render method.

      def delete
        Hyperstack::Internal::Component::RenderingContext.delete(self)
      end
      # Deprecated version of delete method
      alias as_node delete

      private

      # built in events, events going to native components, and events going to reactrb

      # built in events will have their event param translated to the Event wrapper
      # and the name will camelcased and have on prefixed, so :click becomes onClick.
      #
      # events emitting from native components are assumed to have the same camel case and
      # on prefixed.
      #
      # events emitting from reactrb components will just have on_ prefixed.  So
      # :play_button_pushed attaches to the :on_play_button_pushed param
      #
      # in all cases the default name convention can be overriden by wrapping in <...> brackets.
      # So on("<MyEvent>") will attach to the "MyEvent" param.

      def merge_event_prop!(event_name, &block)
        if event_name =~ /^<(.+)>$/
          merge_component_event_prop! event_name.gsub(/^<(.+)>$/, '\1'), &block
        elsif Event::BUILT_IN_EVENTS.include?(name = "on#{event_name.event_camelize}")
          merge_built_in_event_prop! name, &block
        elsif event_name == :enter
          merge_built_in_event_prop!('onKeyDown') { |evt| yield(evt) if evt.key_code == 13 }
        elsif @type.instance_variable_get('@native_import')
          merge_component_event_prop! name, &block
        else
          merge_component_event_prop! "on_#{event_name}", &block
        end
      end

      def merge_built_in_event_prop!(prop_name, &block)
        @properties.merge!(
          prop_name => %x{
            function(){
              var react_event = arguments[0];
              if (arguments.length == 0 || react_event.constructor.name != 'SyntheticEvent') {
                return #{yield(*Array(`arguments`))}
              }
              var all_args;
              var other_args;
              if (arguments.length > 1) {
                all_args = Array.prototype.slice.call(arguments);
                other_args = all_args.slice(1, arguments.length);
                return #{
                  Internal::State::Mapper.ignore_bulk_updates(
                    Event.new(`react_event`), *(`other_args`), &block
                  )
                };
              } else {
                return #{
                  Internal::State::Mapper.ignore_bulk_updates(
                    Event.new(`react_event`), &block
                  )
                };
              }
            }
          }
        )
      end

      def merge_component_event_prop!(prop_name)
        @properties.merge!(
          prop_name => %x{
            function(){
              return #{yield(*Array(`arguments`))}
            }
          }
        )
      end
    end
  end
end
