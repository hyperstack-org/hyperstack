module React
  module Component
    module API
      def dom_node
        `ReactDOM.findDOMNode(#{self}.native)` # react >= v0.15.0
      end

      def mounted?
        `(#{self}.is_mounted === undefined) ? false : #{self}.is_mounted`
      end

      def force_update!
        `#{self}.native.forceUpdate()`
      end

      def set_props(prop, &block)
        raise "set_props: setProps() is no longer supported by react"
      end
      alias :set_props! :set_props

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
        if block
          %x{
            #{self}.native[method](#{state_or_prop.shallow_to_n}, function(){
              #{block.call}
            });
          }
        else
          `#{self}.native[method](#{state_or_prop.shallow_to_n})`
        end
      end
    end
  end
end
