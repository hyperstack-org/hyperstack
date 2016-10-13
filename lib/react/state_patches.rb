module  React
  # add has_observers? and bulk_update methods, and patch set_state so that
  # delayed updates are grouped together and sent at once to update_react_js_state
  # see the component_patches.rb file for how that works
  class State
    class << self
      def has_observers?(object, name)
        !observers_by_name[object][name].empty?
      end

      def set_state2(object, name, value, updates)
        # set object's name state to value, tell all observers it has changed.
        # Observers must implement update_react_js_state
        object_needs_notification = object.respond_to? :update_react_js_state
        observers_by_name[object][name].dup.each do |observer|
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

      def set_state(object, name, value, delay=nil)
        states[object][name] = value
        if delay || @bulk_update_flag
          @delayed_updates ||= []
          @delayed_updates << [object, name, value]
          @delayed_updater ||= after(0.001) do
            delayed_updates = @delayed_updates
            @delayed_updates = []
            @delayed_updater = nil
            updates = Hash.new { |hash, key| hash[key] = Array.new }
            delayed_updates.each do |object, name, value|
              set_state2(object, name, value, updates)
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
