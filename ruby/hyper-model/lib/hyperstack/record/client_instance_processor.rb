module Hyperstack
  module Record
    module ClientInstanceProcessor

      # @private
      def _process_collection_query(methods_hash)
        # collection_query
        methods_hash.keys.each do |method_name|
          collection = Hyperstack::Model::Helpers.collection_from_transport_array(methods_hash[method_name], self) # result is parsed json
          @collection_query[method_name][:result] = collection
          @read_states[method_name] = 'f'
          notify_observers
        end
      end

      # @private
      def _process_collection_query_notification(methods_hash)
        # collection_query
        methods_hash.keys.each do |method_name|
          @read_states[method_name] = 'u'
          send("promise_#{method_name}")
        end
      end

      # @private
      def _process_destroyed(_destroy_result)
        self._local_destroy unless self.destroyed?
      end

      def _process_destroyed_notification(destroy_result)
        _process_destroyed(destroy_result) if destroy_result
      end

      # @private
      def _process_errors(errors_hash)
        errors_hash.keys.each do |name|
          error_message = "#{self.class.to_s} with id #{self.id}: #{name} #{errors_hash[name]}!"
          `console.error(error_message)`
        end
      end

      # @private
      def _process_remote_methods(methods_hash)
        # remote_method
        methods_hash.keys.each do |method_name|
          methods_hash[method_name].keys.each do |args|
            @remote_methods[method_name][args][:result] = methods_hash[method_name][args] # result is parsed json
            @read_states[method_name][args] = 'f'
            notify_observers
          end
        end
      end

      def _process_methods_notification(methods_hash)
        methods_hash.keys.each do |method_name|
          methods_hash[method_name].keys.each do |args|
            @read_states[method_name][args] = 'u'
          end
        end
      end

      # @private
      def _process_properties(properties_hash)
        self._initialize_from_hash(properties_hash)
        self.class._class_read_states[id] = 'f'
      end

      def _process_properties_notification(properties_hash)
        _process_properties(properties_hash)
      end

      # @private
      def _process_relations(relations_hash)
        relations_hash.keys.each do |relation_name|
          if %i[has_many has_and_belongs_to_many].include?(reflections[relation_name][:kind])
            # has_and_belongs_to_many and has_many
            collection = Hyperstack::Model::Helpers.collection_from_transport_array(relations_hash[relation_name], self, relation_name)
            @relations[relation_name] = collection
          else
            # belongs_to and has_one
            @relations[relation_name] = if relations_hash[relation_name]
                                          Hyperstack::Model::Helpers.record_from_transport_hash(relations_hash[relation_name])
                                        else
                                          nil
                                        end
          end
          @read_states[relation_name] = 'f'
        end
      end

      def _process_relations_notification(relations_hash)
        relations_hash.keys.each do |relation_name|
          @read_states[relation_name] = 'u'
          send("promise_#{relation_name}")
        end
      end
    end
  end
end
