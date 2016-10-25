module  React
  # add has_observers? and bulk_update methods, and patch set_state so that
  # delayed updates are grouped together and sent at once to update_react_js_state
  # see the component_patches.rb file for how that works
  class State
    class << self
      def has_observers?(object, name)
        !observers_by_name[object][name].empty?
      end

      def set_state2(object, name, value, updates, exclusions = nil)
        # set object's name state to value, tell all observers it has changed.
        # Observers must implement update_react_js_state
        object_needs_notification = object.respond_to? :update_react_js_state
        observers_by_name[object][name].dup.each do |observer|
          next if exclusions && exclusions.include?(observer)
          updates[observer] += [object, name, value]
          object_needs_notification = false if object == observer
        end
        updates[object] += [nil, name, value] if object_needs_notification
      end

      def bulk_update
        saved_bulk_update_flag = @bulk_update_flag
        @bulk_update_flag = true
        yield
      ensure
        @bulk_update_flag = saved_bulk_update_flag
      end

      def get_state(object, name, current_observer = @current_observer)
        # get current value of name for object, remember that the current object depends on this state,
        # current observer can be overriden with last param
        if current_observer && !new_observers[current_observer][object].include?(name)
          new_observers[current_observer][object] << name
        end
        if @delayed_updates && @delayed_updates[object][name]
          @delayed_updates[object][name][1] << current_observer
        end
        states[object][name]
      end

      def set_state(object, name, value, delay=nil)
        states[object][name] = value
        if delay || @bulk_update_flag
          @delayed_updates ||= Hash.new { |h, k| h[k] = {} }
          @delayed_updates[object][name] = [value, Set.new]
          @delayed_updater ||= after(0.001) do
            delayed_updates = @delayed_updates
            @delayed_updates = Hash.new { |h, k| h[k] = {} } # could this be nil???
            @delayed_updater = nil
            updates = Hash.new { |hash, key| hash[key] = Array.new }
            delayed_updates.each do |object, name_hash|
              name_hash.each do |name, value_and_set|
                set_state2(object, name, value_and_set[0], updates, value_and_set[1])
              end
            end
            updates.each { |observer, args| observer.update_react_js_state(*args) }
          end
        else
          updates = Hash.new { |hash, key| hash[key] = Array.new }
          set_state2(object, name, value, updates)
          updates.each { |observer, args| observer.update_react_js_state(*args) }
        end
        value
      end
    end
  end
end
