require 'react/native_library'

module React
  # Provides the internal mechanisms to interface between reactrb and native components
  # the code will attempt to create a js component wrapper on any rb class that has a
  # render (or possibly _render_wrapper) method.  The mapping between rb and js components
  # is kept in the @@component_classes hash.

  # Also provides the mechanism to build react elements

  # TOOO - the code to deal with components should be moved to a module that will be included
  # in a class which will then create the JS component for that class.  That module will then
  # be included in React::Component, but can be used by any class wanting to become a react
  # component (but without other DSL characteristics.)
  class API
    @@component_classes = {}

    def self.import_native_component(opal_class, native_class)
      opal_class.instance_variable_set("@native_import", true)
      @@component_classes[opal_class] = native_class
    end

    def self.eval_native_react_component(name)
      component = `eval(name)`
      raise "#{name} is not defined" if `#{component} === undefined`
      is_component_class = `#{component}.prototype !== undefined` &&
                            (`!!#{component}.prototype.isReactComponent` ||
                             `!!#{component}.prototype.render`)
      is_functional_component = `typeof #{component} === "function"`
      unless is_component_class || is_functional_component
        raise 'does not appear to be a native react component'
      end
      component
    end

    def self.native_react_component?(name = nil)
      return false unless name
      eval_native_react_component(name)
    rescue
      nil
    end

    def self.create_native_react_class(type)
      raise "Provided class should define `render` method"  if !(type.method_defined? :render)
      render_fn = (type.method_defined? :_render_wrapper) ? :_render_wrapper : :render
      # this was hashing type.to_s, not sure why but .to_s does not work as it Foo::Bar::View.to_s just returns "View"
      @@component_classes[type] ||= %x{
        class extends React.Component {
          constructor(props) {
            super(props);
            this.mixins = #{type.respond_to?(:native_mixins) ? type.native_mixins : `[]`};
            this.statics = #{type.respond_to?(:static_call_backs) ? type.static_call_backs.to_n : `{}`};
            this.state = {};
            this.__opalInstanceInitializedState = false;
            this.__opalInstanceSyncSetState = true;
            this.__opalInstance = #{type.new(`this`)};
            this.__opalInstanceInitializedState = true;
            this.__opalInstanceSyncSetState = false;
            this.__name = #{type.name};
          }
          static get displayName() {
            if (typeof this.__name != "undefined") {
              return this.__name;
            } else {
              return #{type.name};
            }
          }
          static set displayName(name) {
            this.__name = name;
          }
          static get defaultProps() {
            return #{type.respond_to?(:default_props) ? type.default_props.to_n : `{}`};
          }
          static get propTypes() {
            return  #{type.respond_to?(:prop_types) ? type.prop_types.to_n : `{}`};
          }
          componentWillMount() {
            if (#{type.method_defined? :component_will_mount}) {
              this.__opalInstanceSyncSetState = true;
              this.__opalInstance.$component_will_mount();
              this.__opalInstanceSyncSetState = false;
            }
          }
          componentDidMount() {
            this.__opalInstance.is_mounted = true
            if (#{type.method_defined? :component_did_mount}) {
              this.__opalInstanceSyncSetState = false;
              this.__opalInstance.$component_did_mount();
            }
          }
          componentWillReceiveProps(next_props) {
            if (#{type.method_defined? :component_will_receive_props}) {
              this.__opalInstanceSyncSetState = true;
              this.__opalInstance.$component_will_receive_props(Opal.Hash.$new(next_props));
              this.__opalInstanceSyncSetState = false;
            }
          }
          shouldComponentUpdate(next_props, next_state) {
            if (#{type.method_defined? :should_component_update?}) {
              this.__opalInstanceSyncSetState = false;
              return this.__opalInstance["$should_component_update?"](Opal.Hash.$new(next_props), Opal.Hash.$new(next_state));
            } else { return true; }
          }
          componentWillUpdate(next_props, next_state) {
            if (#{type.method_defined? :component_will_update}) {
              this.__opalInstanceSyncSetState = false;
              this.__opalInstance.$component_will_update(Opal.Hash.$new(next_props), Opal.Hash.$new(next_state));
            }
          }
          componentDidUpdate(prev_props, prev_state) {
            if (#{type.method_defined? :component_did_update}) {
              this.__opalInstanceSyncSetState = false;
              this.__opalInstance.$component_did_update(Opal.Hash.$new(prev_props), Opal.Hash.$new(prev_state));
            }
          }
          componentWillUnmount() {
            if (#{type.method_defined? :component_will_unmount}) {
              this.__opalInstanceSyncSetState = false;
              this.__opalInstance.$component_will_unmount();
            }
            this.__opalInstance.is_mounted = false;
          }
          componentDidCatch(error, info) {
            if (#{type.method_defined? :component_did_catch}) {
              this.__opalInstanceSyncSetState = false;
              this.__opalInstance.$component_did_catch(error, Opal.Hash.$new(info));
            }
          }
          render() {
            this.__opalInstanceSyncSetState = false;
            return this.__opalInstance.$send(render_fn).$to_n();
          }
        }
      }
    end

    def self.create_element(type, properties = {}, &block)
      params = []

      # Component Spec, Normal DOM, String or Native Component
      ncc = @@component_classes[type]
      if ncc
        params << ncc
      elsif type.is_a?(Class)
        params << create_native_react_class(type)
      elsif block_given? || React::Component::Tags::HTML_TAGS.include?(type)
        params << type
      elsif type.is_a?(String)
        return React::Element.new(type)
      else
        raise "#{type} not implemented"
      end

      # Convert Passed in properties
      properties = convert_props(properties)
      params << properties.shallow_to_n

      # Children Nodes
      if block_given?
        a = [yield].flatten
        %x{
          for(var i=0, l=a.length; i<l; i++) {
            params.push(a[i].$to_n());
          }
        }
      end
      React::Element.new(`React.createElement.apply(null, #{params})`, type, properties, block)
    end

    def self.clear_component_class_cache
      @@component_classes = {}
    end

    def self.convert_props(properties)
      raise "Component parameters must be a hash. Instead you sent #{properties}" unless properties.is_a? Hash
      props = {}
      properties.each do |key, value|
        if key == "class" || key == "class_name"
          props["className"] = value
        elsif ["style", "dangerously_set_inner_HTML"].include? key
          props[lower_camelize(key)] = value.to_n

        elsif key == "key"
          props["key"] = value.to_key
          
        elsif key == 'ref' && value.is_a?(Proc)
          props[key] = %x{
                          function(dom_node){
                            if (dom_node !== null && dom_node.__opalInstance !== undefined && dom_node.__opalInstance !== null) {
                              #{ value.call(`dom_node.__opalInstance`) };
                            } else if(dom_node !== null && ReactDOM.findDOMNode !== undefined && dom_node.nodeType === undefined) {
                              #{ value.call(`ReactDOM.findDOMNode(dom_node)`) };
                            } else {
                              #{ value.call(`dom_node`) };
                            }
                          }
                        }
        elsif React::HASH_ATTRIBUTES.include?(key) && value.is_a?(Hash)
          value.each { |k, v| props["#{key}-#{k.tr('_', '-')}"] = v.to_n }
        else
          props[React.html_attr?(lower_camelize(key)) ? lower_camelize(key) : key] = value
        end
      end
      props
    end

    private

    def self.lower_camelize(snake_cased_word)
      words = snake_cased_word.split('_')
      result = [words.first]
      result.concat(words[1..-1].map {|word| word[0].upcase + word[1..-1] }).join('')
    end
  end
end
