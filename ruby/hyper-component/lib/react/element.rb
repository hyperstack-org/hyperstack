require 'react/ext/string'

module React
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

    # Attach event handlers.

    def on(*event_names, &block)
      event_names.each { |event_name| merge_event_prop!(event_name, &block) }
      @native = `React.cloneElement(#{@native}, #{@properties.shallow_to_n})`
      self
    end

    # Render element into DOM in the current rendering context.
    # Used for elements that are not yet in DOM, i.e. they are provided as children
    # or they have been explicitly removed from the rendering context using the delete method.

    def render(props = {}, &new_block)
      if props.empty?
        React::RenderingContext.render(self)
      else
        props = API.convert_props(props)
        React::RenderingContext.render(
          Element.new(`React.cloneElement(#{@native}, #{props.shallow_to_n})`,
                      type, @properties.merge(props), block),
        )
      end
    end

    # Delete (remove) element from rendering context, the element may later be added back in
    # using the render method.

    def delete
      React::RenderingContext.delete(self)
    end
    # Deprecated version of delete method
    alias as_node delete

    # Any other method applied to an element will be treated as class name (haml style) thus
    # div.foo.bar(id: :fred) is the same as saying div(class: "foo bar", id: :fred)
    #
    # single underscores become dashes, and double underscores become a single underscore
    #
    # params may be provide to each class (but typically only to the last for easy reading.)

    def method_missing(class_name, args = {}, &new_block)
      return dup.render.method_missing(class_name, args, &new_block) unless rendered?
      React::RenderingContext.replace(
        self,
        RenderingContext.build do
          RenderingContext.render(type, build_new_properties(class_name, args), &new_block)
        end
      )
    end

    def rendered?
      React::RenderingContext.rendered? self
    end

    def self.haml_class_name(class_name)
      class_name.gsub(/__|_/, '__' => '_', '_' => '-')
    end

    private

    def build_new_properties(class_name, args)
      class_name = self.class.haml_class_name(class_name)
      new_props = @properties.dup
      new_props[:className] = "\
        #{class_name} #{new_props[:className]} #{args.delete(:class)} #{args.delete(:className)}\
      ".split(' ').uniq.join(' ')
      new_props.merge! args
    end

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
      elsif React::Event::BUILT_IN_EVENTS.include?(name = "on#{event_name.event_camelize}")
        merge_built_in_event_prop! name, &block
      elsif @type.instance_variable_get('@native_import')
        merge_component_event_prop! name, &block
      else
        merge_component_event_prop! "on_#{event_name}", &block
      end
    end

    def merge_built_in_event_prop!(prop_name)
      @properties.merge!(
        prop_name => %x{
          function(){
            var react_event = arguments[0];
            var all_args;
            var other_args;
            if (arguments.length > 1) {
              all_args = Array.prototype.slice.call(arguments);
              other_args = all_args.slice(1, arguments.length);
              return #{yield(React::Event.new(`react_event`), *(`other_args`))};
            } else {
              return #{yield(React::Event.new(`react_event`))};
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
