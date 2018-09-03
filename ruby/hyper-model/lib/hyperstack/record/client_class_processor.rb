module Hyperstack
  module Record
    module ClientClassProcessor
      def process_notification(notification_hash)
        notification_hash.keys.each do |notifyable|
          send("_process_#{notifyable}_notification", notification_hash[notifyable])
        end
        nil
      end

      def process_response(response_hash)
        records_to_notify = [] # could be a Set maybe
        response_hash.keys.each do |readables|
          if readables == :instances
            send("_process_class_#{readables}", response_hash[readables], records_to_notify)
          else
            send("_process_class_#{readables}", response_hash[readables])
          end
        end
        records_to_notify.each(&:notify_observers)
        # notify_class_observers
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
        instances_hash.keys.each do |agent_object_id|
          agent = Hyperstack::Transport::RequestAgent.get(agent_object_id)
          if instances_hash[agent_object_id].has_key?(:errors)
            agent.result = nil
            agent.errors = instances_hash[agent_object_id][:errors]
          else
            instances_hash[agent_object_id].keys.each do |find_by_method|
              agent.result = Hyperstack::Model::Helpers.record_from_transport_hash(instances_hash[agent_object_id][find_by_method])
            end
          end
        end
      end

      # @private
      def _process_class_instances(instances_hash, records_to_notify)
        instances_hash.keys.each do |id|
          record = if record_cached?(id)
                     _record_cache[id]
                   else
                     self.new(id: id)
                   end

          instances_hash[id].keys.each do |readables|
            record.send("_process_#{readables}", instances_hash[id][readables])
          end
          records_to_notify << record
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
        where_hash.keys.each do |agent_object_id|
          agent = Hyperstack::Transport::RequestAgent.get(agent_object_id)
          if where_hash[agent_object_id].has_key?(:error)
            agent.result = nil
            agent.errors = where_hash[agent_object_id][:errors]
          else
            agent.result = Hyperstack::Model::Helpers.collection_from_transport_array(where_hash[agent_object_id])
            _class_read_states[scope_name][args] = 'f'
          end
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