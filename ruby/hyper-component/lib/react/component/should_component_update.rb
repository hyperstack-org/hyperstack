module React
  module Component
    #
    # React assumes all components should update, unless a component explicitly overrides
    # the shouldComponentUpdate method.  Reactrb does an explicit check doing a shallow
    # compare of params, and using a timestamp to determine if state has changed.

    # If needed components can provide their own #needs_update? method which will be
    # passed the next params and state opal hashes.

    # Attached to these hashes is a #changed? method that returns whether the hash contains
    # changes as calculated by the base mechanism.  This way implementations of #needs_update?
    # can use the base comparison mechanism as needed.

    # For example
    # def needs_update?(next_params, next_state)
    #   # use a special comparison method
    #   return false if next_state.changed? || next_params.changed?
    #   # do some other special checks
    # end

    # Note that beginning in 0.9 we will use standard ruby compare on all params further reducing
    # the need for needs_update?
    #
    module ShouldComponentUpdate
      def should_component_update?(next_props, next_state)
        State.set_state_context_to(self, false) do
          # rubocop:disable Style/DoubleNegation # we must return true/false to js land
          if respond_to?(:needs_update?)
            !!call_needs_update(next_props, next_state)
          else
            (props_changed?(next_props) || native_state_changed?(next_state))
          end
          # rubocop:enable Style/DoubleNegation
        end
      end

      # create opal hashes for next params and state, and attach
      # the changed? method to each hash

      def call_needs_update(next_params, next_state)
        component = self
        next_params.define_singleton_method(:changed?) do
          component.props_changed?(self)
        end
        next_state.define_singleton_method(:changed?) do
          component.native_state_changed?(next_state)
        end
        needs_update?(next_params, next_state)
      end

      # Whenever state changes, reactrb updates a timestamp on the state object.
      # We can rapidly check for state changes comparing the incoming state time_stamp
      # with the current time stamp.

      # we receive a Opal Ruby Hash here, always, so the Hash is either empty or filled
      # Hash is converted to native object
      # if the Hash was empty, the Object has no keys

      # Different versions of react treat empty state differently, so we first
      # convert anything that looks like an empty state to "false" for consistency.

      # Then we test if one state is empty and the other is not, then we return false.
      # Then we test if both states are empty we return true.
      # If either state does not have a time stamp then we have to assume a change.
      # Otherwise we check time stamps

      # rubocop:disable Metrics/MethodLength # for effeciency we want this to be one method
      def native_state_changed?(next_state_hash)
        # next_state = next_state_hash.to_n
        # %x{
        #   var current_state = #{@native}.state
        #   var normalized_next_state =
        #     !next_state || Object.keys(next_state).length === 0 ? false : next_state
        #   var normalized_current_state =
        #     !current_state || Object.keys(current_state).length === 0 ? false : current_state
        #   if (!normalized_current_state != !normalized_next_state) return(true)
        #   if (!normalized_current_state && !normalized_next_state) return(false)
        #   if (!normalized_current_state['***_state_updated_at-***'] &&
        #     !normalized_next_state['***_state_updated_at-***']) return(false)
        #   if (!normalized_current_state['***_state_updated_at-***'] ||
        #       !normalized_next_state['***_state_updated_at-***']) return(true)
        #   return (normalized_current_state['***_state_updated_at-***'] !=
        #           normalized_next_state['***_state_updated_at-***'])
        # }
        state_hash = Hash.new(`#{@native}.state`)
        next_state_hash != state_hash
      end
      # rubocop:enable Metrics/MethodLength

      # Do a shallow compare on the two hashes. Starting in 0.9 we will do a deep compare. ???

      def props_changed?(next_props)
        props = Hash.new(`#{@native}.props`)
        next_props != props
      end
    end
  end
end
