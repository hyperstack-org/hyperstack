require 'hyperstack/component/native_library'

module Hyperstack
  module Internal
    module Component
      # contains the name of all HTML tags, and the mechanism to register a component
      # Provides the internal mechanisms to interface between reactrb and native components
      # the code will attempt to create a js component wrapper on any rb class that has a
      # render (or possibly _render_wrapper) method.  The mapping between rb and js components
      # is kept in the @@component_classes hash.

      # Also provides the mechanism to build react elements

      # TOOO - the code to deal with components should be moved to a module that will be included
      # in a class which will then create the JS component for that class.  That module will then
      # be included in React::Component, but can be used by any class wanting to become a react
      # component (but without other DSL characteristics.)
      class ReactWrapper
        @@component_classes = {}

        def self.stateless?(ncc)
          %x{
            typeof #{ncc} === 'function' // can be various things
            && !(
              #{ncc}.prototype // native arrows don't have prototypes
              && #{ncc}.prototype.isReactComponent // special property
            )
          }
        end

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
          has_render_method = `typeof #{component}.render === "function"`
          unless is_component_class || stateless?(component) || has_render_method
            raise 'does not appear to be a native react component'
          end
          component
        end

        def self.native_react_component?(name = nil)
          return false unless name
          eval_native_react_component(name)
          true
        rescue
          false
        end

        def self.add_after_error_hook(klass)
          add_after_error_hook_to_native(@@component_classes[klass])
        end

        def self.add_after_error_hook_to_native(native_comp)
          return unless native_comp
          %x{
            native_comp.prototype.componentDidCatch = function(error, info) {
              this.__opalInstanceSyncSetState = false;
              this.__opalInstance.$component_did_catch(error, Opal.Hash.$new(info));
            }
          }
        end

        def self.create_native_react_class(type)
          raise "Provided class should define `render` method"  if !(type.method_defined? :render)
          render_fn = (type.method_defined? :_render_wrapper) ? :_render_wrapper : :render
          # this was hashing type.to_s, not sure why but .to_s does not work as it Foo::Bar::View.to_s just returns "View"

          @@component_classes[type] ||= begin
            comp = %x{
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
                  this.__opalInstance.__hyperstack_component_is_mounted = true
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
                  this.__opalInstance.__hyperstack_component_is_mounted = false;
                }

                render() {
                  this.__opalInstanceSyncSetState = false;
                  return this.__opalInstance.$send(render_fn).$to_n();
                }
              }
            }
            # check to see if there is an after_error callback.  If there is add a
            # componentDidCatch handler. Because legacy behavior is to allow any object
            # that responds to render to act as a component we have to make sure that
            # we have a callbacks_for method.  This all becomes much easier once issue
            # #270 is resolved.
            if type.respond_to?(:callbacks?) && type.callbacks?(:after_error)
              add_after_error_hook_to_native comp
            end
            comp
          end
        end

        def self.create_element(type, *args, &block)
          params = []

          # Component Spec, Normal DOM, String or Native Component
          ncc = @@component_classes[type]
          if ncc
            params << ncc
          elsif type.is_a?(Class)
            params << create_native_react_class(type)
          elsif block_given? || Tags::HTML_TAGS.include?(type)
            params << type
          elsif type.is_a?(String)
            return Hyperstack::Component::Element.new(type)
          else
            raise "#{type} not implemented"
          end

          # Convert Passed in properties
          ele = nil # create nil var for the ref to use
          ref = ->(ref) { ele._update_ref(ref) } unless stateless?(ncc)
          properties = convert_props(type, { ref: ref }, *args)
          params << properties.shallow_to_n

          # Children Nodes
          if block
            a = [block.call].flatten
            %x{
              for(var i=0, l=a.length; i<l; i++) {
                params.push(a[i].$to_n());
              }
            }
          end
          Hyperstack::Component::Element.new(
            `React.createElement.apply(null, #{params})`, type, properties, block
          )
        end

        def self.clear_component_class_cache
          @@component_classes = {}
        end

        def self.convert_props(type, *args)
          # merge args together into a single properties hash
          properties = {}
          args.each do |arg|
            if arg.is_a? String
              properties[arg] = true
            elsif arg.is_a? Hash
              arg.each do |key, value|
                if ['class', 'className', 'class_name'].include? key
                  next unless value

                  if value.is_a?(String)
                    value = value.split(' ')
                  elsif !value.is_a?(Array)
                    raise "The class param must be a string or array of strings"
                  end

                  properties['className'] = [*properties['className'], *value]
                elsif key == 'style'
                  next unless value

                  if !value.is_a?(Hash)
                    raise "The style param must be a Hash"
                  end

                  properties['style'] = (properties['style'] || {}).merge(value)
                elsif Hyperstack::Component::ReactAPI::HASH_ATTRIBUTES.include?(key) && value.is_a?(Hash)
                  properties[key] = (properties[key] || {}).merge(value)
                else
                  properties[key] = value
                end
              end
            end
          end
          # process properties according to react rules
          props = {}
          properties.each do |key, value|
            if %w[style dangerously_set_inner_HTML].include? key
              props[lower_camelize(key)] = value.to_n

            elsif key == :className
              props[key] = value.join(' ')

            elsif key == :key
              props[:key] = value.to_key

            elsif key == :init
              if %w[select textarea].include? type
                key = :defaultValue
              elsif type == :input
                key = if %w[radio checkbox].include? properties[:type]
                        :defaultChecked
                      else
                        :defaultValue
                      end
              end
              props[key] = value

            elsif key == 'ref'
              next unless value
              unless value.respond_to?(:call)
                raise "The ref and dom params must be given a Proc.\n"\
                      "If you want to capture the ref in an instance variable use the `set` method.\n"\
                      "For example `ref: set(:TheRef)` will capture assign the ref to `@TheRef`\n"
              end
              unless `value.__hyperstack_component_ref_is_already_wrapped`
                fn = value
                value = %x{
                          function(dom_node){
                            if (dom_node !== null && dom_node.__opalInstance !== undefined && dom_node.__opalInstance !== null) {
                              #{ Hyperstack::Internal::State::Mapper.ignore_mutations { fn.call(`dom_node.__opalInstance`) } };
                            } else if(dom_node !== null && ReactDOM.findDOMNode !== undefined && dom_node.nodeType === undefined) {
                              #{ Hyperstack::Internal::State::Mapper.ignore_mutations { fn.call(`ReactDOM.findDOMNode(dom_node)`) } };
                            } else if(dom_node !== null){
                              #{ Hyperstack::Internal::State::Mapper.ignore_mutations { fn.call(`dom_node`) } };
                            }
                          }
                        }
                `value.__hyperstack_component_ref_is_already_wrapped = true`
              end
              props[key] = value
            elsif key == 'jq_ref'
              unless value.respond_to?(:call)
                raise "The ref and dom params must be given a Proc.\n"\
                      "If you want to capture the dom node in an instance variable use the `set` method.\n"\
                      "For example `dom: set(:DomNode)` will assign the dom node to `@DomNode`\n"
              end
              unless Module.const_defined? 'Element'
                raise "You must include 'hyperstack/component/jquery' "\
                      "in your manifest to use the `dom` reference key.\n"\
                      'For example if using rails include '\
                      "`config.import 'hyperstack/component/jquery', client_only: true`"\
                      'in your config/initializer/hyperstack.rb file'
              end
              props[:ref] = %x{
                              function(dom_node){
                                if (dom_node !== null && dom_node.__opalInstance !== undefined && dom_node.__opalInstance !== null) {
                                  #{ Hyperstack::Internal::State::Mapper.ignore_mutations { value.call(::Element[`dom_node.__opalInstance`]) } };
                                } else if(dom_node !== null && ReactDOM.findDOMNode !== undefined && dom_node.nodeType === undefined) {
                                  #{ Hyperstack::Internal::State::Mapper.ignore_mutations { value.call(::Element[`ReactDOM.findDOMNode(dom_node)`]) } };
                                } else if(dom_node !== null) {
                                  #{ Hyperstack::Internal::State::Mapper.ignore_mutations { value.call(::Element[`dom_node`]) } };
                                }
                              }
                            }

            elsif Hyperstack::Component::ReactAPI::HASH_ATTRIBUTES.include?(key) && value.is_a?(Hash)
              value.each { |k, v| props["#{key}-#{k.gsub(/__|_/, '__' => '_', '_' => '-')}"] = v.to_n }
            else
              props[Hyperstack::Component::ReactAPI.html_attr?(lower_camelize(key)) ? lower_camelize(key) : key] = value
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
  end
end
