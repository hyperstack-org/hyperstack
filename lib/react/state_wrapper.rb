module HyperStore
  class StateWrapper < BaseStoreClass # < BasicObject

    def [](state)
      `#{__from__.instance_variable_get('@native')}.state[#{state}] || #{nil}`
    end

    def []=(state, new_value)
      `#{__from__.instance_variable_get('@native')}.state[#{state}] = new_value`
    end

    alias pre_component_method_missing method_missing

    def method_missing(method, *args)
      if method.end_with?('!') && __from__.respond_to?(:deprecation_warning)
        __from__.deprecation_warning("The mutator 'state.#{method}' has been deprecated.  Use 'mutate.#{method.sub(/\!$/,'')}' instead.")
        __from__.mutate.__send__(method.chop, *args)
      else
        pre_component_method_missing(method, *args)
      end
    end
  end
end
