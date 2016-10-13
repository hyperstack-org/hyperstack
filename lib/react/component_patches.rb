module React
  # allow update_react_js_state to accept multiple state updates at once
  # this prevents multiple renders when synchromesh updates occur
  module Component
    def update_react_js_state(*args)
      set_state(update_react_js_state2({}, *args))
    end

    def update_react_js_state2(h, object, name, value, *args)
      if object
        h['***_state_updated_at-***'] = Time.now.to_f
        h["#{object.class.to_s + '.' unless object == self}#{name}"] = value
      else
        h[name] = value
      end
      update_react_js_state2(h, *args) unless args.empty?
      h
    end
  end
end
