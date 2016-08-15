module  React
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
          #observer.update_react_js_state(object, name, value)
          object_needs_notification = false if object == observer
        end
        #object.update_react_js_state(nil, name, value) if object_needs_notification
        updates[object] += [nil, name, value] if object_needs_notification
      end

      def set_state(object, name, value, delay=nil)
        states[object][name] = value
        if delay
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
      rescue Exception => e
        puts "set_state(object, name, value, delay) failed #{e}"
      end
    end
  end
end
