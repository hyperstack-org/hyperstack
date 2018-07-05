module HyperRecord
  class NotificationProcessor
    # @private
    def self.process(data)
      record_class = Object.const_get(data[:record_type])
      if data[:scope]
        scope_name, scope_params = data[:scope].split('_[')
        if scope_params
          scope_params = '[' + scope_params
          record_class._class_fetch_states[data[:scope]] = 'u'
          record_class.send("promise_#{scope_name}", *JSON.parse(scope_params)).then do |collection|
            record_class._notify_class_observers
          end.fail do |response|
            error_message = "#{record_class}.#{scope_name}(#{scope_params}), a scope failed to update!"
            `console.error(error_message)`
          end
        else
          record_class._class_fetch_states[data[:scope]] = 'u'
          record_class.send(data[:scope]).then do |collection|
            record_class._notify_class_observers
          end.fail do |response|
            error_message = "#{record_class}.#{scope_name}, a scope failed to update!"
            `console.error(error_message)`
          end
        end
      elsif data[:rest_class_method]
        record_class._class_fetch_states[data[:rest_class_method]] = 'u'
        if data[:rest_class_method].include?('_[')
          record_class._notify_class_observers
        else
          send("promise_#{data[:rest_class_method]}").then do |result|
            _notify_observers
          end.fail do |response|
            error_message = "#{self}[#{self.id}].#{data[:rest_class_method]} failed to update!"
            `console.error(error_message)`
          end
        end
      elsif record_class.record_cached?(data[:id])
        record_class._record_cache[data[:id].to_s]._update_record(data)
      elsif data[:destroyed]
        return
      end
    end
  end
end