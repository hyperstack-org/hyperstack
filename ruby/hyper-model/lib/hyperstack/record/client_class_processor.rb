module Hyperstack
  module Record
    module ClientClassProcessor
      def process_notification(notification_hash)
        notification_hash.keys.each do |notifyable|
          send("_process_#{notifyable}_notification", notification_hash[notifyable])
        end
        nil
      end

      def process_response(promise, response_hash)
        response_hash.keys.each do |readables|
          send("_process_class_#{readables}", response_hash[readables])
        end
        nil
      end

      # @private
      def _process_class_errors(errors_hash)
        errors_hash.keys.each do |name|
          # raise "#{self.to_s}: #{errors_hash[name]}"
          error_message = "#{self.to_s}: #{name} #{errors_hash[name]}"
          `console.error(error_message)`
        end
      end

      # @private
      def _process_class_find_by(instances_hash)
        if instances_hash.has_key?(:errors)
          promise.reject(instances_hash[:errors])
        else
          instances_hash.keys.each do |find_by_method|
            Hyperstack::Model::Helpers.record_from_transport_hash(instances_hash[find_by_method])
          end
        end
      end

      # @private
      def _process_class_instances(instances_hash)
        instances_hash.keys.each do |id|
          record = if record_cached?(id)
                     _record_cache[id]
                   else
                     self.new(id: id)
                   end

          instances_hash[id].keys.each do |readables|
            record.send("_process_#{readables}", instances_hash[id][readables])
          end
        end
      end

      # @private
      def _process_class_scopes(scopes_hash)
        # scope
        scopes_hash.keys.each do |scope_name|
          scopes_hash[scope_name].keys.each do |args|
            scopes[scope_name][args] = Hyperstack::Model::Helpers.collection_from_transport_array(scopes_hash[scope_name][args])
            _class_read_states[scope_name][args] = 'f'
          end
        end
      end

      # @private
      def _process_class_remote_methods(methods_hash)
        # rest_class_method
        methods_hash.keys.each do |method_name|
          methods_hash[method_name].keys.each do |args|
            rest_class_methods[method_name][args] = methods_hash[method_name][args] # result is parsed json
            _class_read_states[method_name][args] = 'f'
          end
        end
      end

      # @private
      def _process_class_where(where_hash)
        # scope
        if where_hash.has_key?(:error)
          where_hash[:errors]
        else
          Hyperstack::Model::Helpers.collection_from_transport_array(where_hash)
          _class_read_states[scope_name][args] = 'f'
        end
      end

      # @private
      def _process_instances_notification(instances_hash)
        instances_hash.keys.each do |id|
          record = if record_cached?(id)
                     _record_cache[id]
                   else
                     self.new(id: id)
                   end
          instances_hash[id].keys.each do |notifyables|
            record.send("_process_#{notifyables}_notification", instances_hash[id][notifyables])
          end
        end
      end

      # @private
      def _process_methods_notification(notification_hash)
        notification_hash.keys.each do |method_name|
          _class_read_states[method_name].keys.each do |args|
            _class_read_states[method_name][args] = 'u'
            if args != '[]'
              notify_class_observers
            else
              send("promise_#{method_name}")
            end
          end
        end
      end

      # @private
      def _process_scopes_notification(notification_hash)
        notification_hash.keys.each do |scope_name|
          _class_read_states[scope_name].keys.each do |args|
            _class_read_states[scope_name][args] = 'u'
            send("promise_#{scope_name}", *JSON.parse(args))
          end
        end
      end

    end
  end
end