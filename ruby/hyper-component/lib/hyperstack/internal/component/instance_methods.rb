require "hyperstack/component/children"

module Hyperstack
  module Internal
    module Component
      module InstanceMethods
        def children
          Hyperstack::Component::Children.new(`#{@native}.props.children`)
        end

        def params
          @params ||= self.class.props_wrapper.new(self)
        end

        def props
          Hash.new(`#{@native}.props`)
        end

        def refs
          Hash.new(`#{@native}.refs`)
        end

        def dom_node
          `ReactDOM.findDOMNode(#{self}.native)` # react >= v0.15.0
        end

        def mounted?
          `(#{self}.is_mounted === undefined) ? false : #{self}.is_mounted`
        end

        def force_update!
          `#{self}.native.forceUpdate()`
          self
        end

        def set_state(state, &block)
          set_or_replace_state_or_prop(state, 'setState', &block)
        end

        def set_state!(state, &block)
          set_or_replace_state_or_prop(state, 'setState', &block)
          `#{self}.native.forceUpdate()`
        end

        private

        def set_or_replace_state_or_prop(state_or_prop, method, &block)
          raise "No native ReactComponent associated" unless @native
          `var state_prop_n = #{state_or_prop.shallow_to_n}`
          # the state object is initalized when the ruby component is instantiated
          # this is detected by self.native.__opalInstanceInitializedState
          # which is set in the native component constructor in ReactWrapper
          # the setState update callback is not called when initalizing initial state
          if block
            %x{
              if (#{@native}.__opalInstanceInitializedState === true) {
                #{@native}[method](state_prop_n, function(){
                  block.$call();
                });
              } else {
                for (var sp in state_prop_n) {
                  if (state_prop_n.hasOwnProperty(sp)) {
                    #{@native}.state[sp] = state_prop_n[sp];
                  }
                }
              }
            }
          else
            %x{
              if (#{@native}.__opalInstanceInitializedState === true) {
                #{@native}[method](state_prop_n);
              } else {
                for (var sp in state_prop_n) {
                  if (state_prop_n.hasOwnProperty(sp)) {
                    #{@native}.state[sp] = state_prop_n[sp];
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
