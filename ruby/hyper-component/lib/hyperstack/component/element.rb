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

#       $$typeof: Symbol(react.element)
#       key: null
#       props: {}
#       ref: null
#       type: "div"
# _     _owner: null

      attr_reader   :type

      attr_reader :element_type # change this so name does not conflict - change to element type
      attr_reader :properties
      attr_reader :block
      attr_reader :to_n

      attr_accessor :waiting_on_resources

      def set_native_attributes(native_element)
        @key =    `native_element.key`
        @props =  `native_element.props`
        @ref =    `native_element.ref`
        @type =   `native_element.type`
        @_owner = `native_element._owner`
        @_props_as_hash = Hash.new(@props)
      end

      def props
        @_props_as_hash
      end

      def convert_string(native_element, element_type, props, block)
        return native_element unless `native_element['$is_a?']`
        return native_element unless native_element.is_a? String
        raise "Internal Error Element.new called with string, but non-nil props or block" if !props.empty? || block

        if element_type == :wrap_child
          `React.createElement(React.Fragment, null, [native_element])`
        else
          `React.createElement(native_element, null)`
        end
      end

      def initialize(native_element, element_type = nil, properties = {}, block = nil)

        native_element = convert_string(native_element, element_type, properties, block)
        @element_type = element_type unless element_type == :wrap_child
        @properties = (`typeof #{properties} === 'undefined'` ? nil : properties) || {}
        @block = block
        `#{self}.$$typeof = native_element.$$typeof`
        @to_n = self
        set_native_attributes(native_element)
      rescue Exception
      end

      def children
        `#{@props}.children`
      end

      def _update_ref(x)
        @_ref = x
        @_child_element._update_ref(x) if @_child_element
      end

      def ref # this will not conflict with React's on ref attribute okay because its $ref!!!
        return @_ref if @_ref
        raise("The instance of #{self.element_type} has not been mounted yet") if properties[:ref]
        raise("Attempt to get a ref on #{self.element_type} which is a static component.")
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
        set_native_attributes(`React.cloneElement(#{self}, #{@properties.shallow_to_n})`) if any_found
        self
      end

      # Render element into DOM in the current rendering context.
      # Used for elements that are not yet in DOM, i.e. they are provided as children
      # or they have been explicitly removed from the rendering context using the delete method.

      def render(*props)
        if props.empty?
          Hyperstack::Internal::Component::RenderingContext.render(self)
        else
          props = Hyperstack::Internal::Component::ReactWrapper.convert_props(element_type, @properties, *props)
          @_child_element = Hyperstack::Internal::Component::RenderingContext.render(
            Element.new(`React.cloneElement(#{self}, #{props.shallow_to_n})`,
                        element_type, props, block)
          )
        end
      end

      # Delete (remove) element from rendering context, the element may later be added back in
      # using the render method.

      def ~
        Hyperstack::Internal::Component::RenderingContext.delete(self)
      end
      # Deprecated version of delete method
      alias as_node ~
      alias delete ~

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
        elsif element_type.instance_variable_get('@native_import')
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
              if (arguments.length == 0 || !react_event.nativeEvent) {
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
