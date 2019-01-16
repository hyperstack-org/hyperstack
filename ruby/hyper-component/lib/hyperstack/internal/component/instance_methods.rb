require "hyperstack/component/children"

module Hyperstack
  module Internal
    module Component
      module InstanceMethods
        def children
          Hyperstack::Component::Children.new(`#{@__hyperstack_component_native}.props.children`)
        end

        def params
          if [:hyperstack, :accessors].include? @__hyperstack_component_params_wrapper.param_accessor_style
            raise "params are now directly accessible via instance variables.\n"\
                  '  to access the legacy behavior add `param_accessor_style = :legacy` '\
                    "to your component class\n"\
                  '  to access both behaviors add `param_accessor_style = :both` '\
                    'to your component class'
          end
          @__hyperstack_component_params_wrapper
        end

        def props
          Hash.new(`#{@__hyperstack_component_native}.props`)
        end

        def dom_node
          `ReactDOM.findDOMNode(#{self}.__hyperstack_component_native)` # react >= v0.15.0
        end

        def jq_node
          ::Element[dom_node]
        end

        def mounted?
          `(#{self}.__hyperstack_component_is_mounted === undefined) ? false : #{self}.__hyperstack_component_is_mounted`
        end

        def pluralize(count, singular, plural = nil)
          word = if (count == 1 || count =~ /^1(\.0+)?$/)
            singular
          else
            plural || singular.pluralize
          end

          "#{count || 0} #{word}"
        end

        def force_update!
          `#{self}.__hyperstack_component_native.forceUpdate()`
          self
        end

        def set_state(state, &block)
          set_or_replace_state_or_prop(state, 'setState', &block)
        end

        def set_state!(state, &block)
          set_or_replace_state_or_prop(state, 'setState', &block)
          `#{self}.__hyperstack_component_native.forceUpdate()`
        end

        private

        # can be overriden by the Router include
        def __hyperstack_router_wrapper(&block)
          ->() { instance_eval(&block) }
        end

        # can be overriden by including WhileLoading include
        def __hyperstack_component_rescue_wrapper(child)
          if self.class.callbacks?(:__hyperstack_component_rescue_hook)
            Hyperstack::Internal::Component::RescueWrapper(child: self, children_elements: child)
          else
            child.call
          end
        end

        def __hyperstack_component_select_wrappers(&block)
          RescueWrapper.after_error_args = nil
          __hyperstack_component_run_post_render_hooks(
            __hyperstack_component_rescue_wrapper(
              __hyperstack_router_wrapper(&block)
            )
          )
        end

        def set_or_replace_state_or_prop(state_or_prop, method, &block)
          raise "No native ReactComponent associated" unless @__hyperstack_component_native
          `var state_prop_n = #{state_or_prop.shallow_to_n}`
          # the state object is initalized when the ruby component is instantiated
          # this is detected by self.__hyperstack_component_native.__opalInstanceInitializedState
          # which is set in the native component constructor in ReactWrapper
          # the setState update callback is not called when initalizing initial state
          if block
            %x{
              if (#{@__hyperstack_component_native}.__opalInstanceInitializedState === true) {
                #{@__hyperstack_component_native}[method](state_prop_n, function(){
                  block.$call();
                });
              } else {
                for (var sp in state_prop_n) {
                  if (state_prop_n.hasOwnProperty(sp)) {
                    #{@__hyperstack_component_native}.state[sp] = state_prop_n[sp];
                  }
                }
              }
            }
          else
            %x{
              if (#{@__hyperstack_component_native}.__opalInstanceInitializedState === true) {
                #{@__hyperstack_component_native}[method](state_prop_n);
              } else {
                for (var sp in state_prop_n) {
                  if (state_prop_n.hasOwnProperty(sp)) {
                    #{@__hyperstack_component_native}.state[sp] = state_prop_n[sp];
                  }
                }
              }
            }
          end
        end
      end
    end
  end
end
