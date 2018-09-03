module Hyperstack
  module Model
    module PubSub
      class << self
        def publish_record(record)
          message = { notification:
                        { record.class.to_s.underscore => { instances: { record.id => { properties: record.as_json, destroyed: record.destroyed? }}}}}
          object_string = "HRPS__#{record.class}__#{record.id}"

          Hyperstack::Transport::ServerPubSub.publish(object_string, message)
          Hyperstack::Transport::ServerPubSub.unsubscribe_all(object_string) if record.destroyed?
        end

        def publish_relation(base_record, relation_name, record = nil)
          message = { notification:
                        { base_record.class.to_s.underscore => { instances: { base_record.id => { properties: {
                          updated_at: base_record.updated_at,
                          destroyed: base_record.destroyed?,
                          relation: { relation_name => { record.class.to_s.underscore => { instances: { record.id => { properties: {
                            updated_at: record.updated_at,
                            destroyed: record.destroyed?
                          }}}}}}}}}}}}

          object_string = "HRPS__#{base_record.class}__#{base_record.id}__#{relation_name}"

          Hyperstack::Transport::ServerPubSub.publish(object_string, message)
        end

        def publish_rest_class_method(record_class, method_name)
          s_method_name, s_method_args = method_name.to_s.split('_[')
          s_method_args = s_method_args ? '[' + s_method_args : '[]'
          message = { notification: { record_class.to_s.underscore => { methods: { s_method_name => { s_method_args => nil } }}}}

          object_string = "HRPS__#{record_class}__rest_class_method__#{method_name}"
          Hyperstack::Transport::ServerPubSub.publish(object_string, message)
        end

        def publish_remote_method(record, method_name)
          s_method_name, s_method_args = method_name.to_s.split('_[')
          s_method_args = s_method_args ? '[' + s_method_args : '[]'
          message = { notification: { record.class.to_s.underscore => { instances: { record.id => { properties: {
            updated_at: record.updated_at,
            destroyed: record.destroyed?
          }, methods: { s_method_name => { s_method_args => nil } }}}}}}

          object_string = "HRPS__#{record.class}__#{record.id}__remote_method__#{method_name}"
          Hyperstack::Transport::ServerPubSub.publish(object_string, message)
        end

        def publish_scope(record_class, scope_name)
          s_scope_name, s_scope_args = scope_name.to_s.split('_[')
          s_scope_args = s_scope_args ? '[' + s_scope_args : '[]'
          message = { notification: { record_class.to_s.underscore => { scopes: { s_scope_name => { s_scope_args => nil } }}}}

          object_string = "HRPS__#{record_class}__scope__#{scope_name}"
          Hyperstack::Transport::ServerPubSub.publish(object_string, message)
        end

        def subscribe_record(session_id, record)
          return unless session_id
          object_string = "HRPS__#{record.class}__#{record.id}"
          Hyperstack::Transport::ServerPubSub.subscribe(object_string, session_id)
        end

        def subscribe_relation(session_id, relation, base_record = nil, relation_name = nil)
          return unless session_id
          object_strings = []
          if relation.is_a?(Enumerable)
            # has_many
            relation.each do |record|
              object_strings << "HRPS__#{record.class}__#{record.id}"
            end
          elsif !relation.nil?
            # has_one, belongs_to, relation is actually a record
            object_strings << "HRPS__#{relation.class}__#{relation.id}"
          end
          object_strings << "HRPS__#{base_record.class}__#{base_record.id}__#{relation_name}" if base_record && relation_name
          Hyperstack::Transport::ServerPubSub.subscribe_to_many(object_strings, session_id)
        end

        def subscribe_rest_class_method(session_id, record_class, rest_class_method_name)
          return unless session_id
          object_string = "HRPS__#{record_class}__rest_class_method_name__#{rest_class_method_name}"
          Hyperstack::Transport::ServerPubSub.subscribe(object_string, session_id)
        end

        def subscribe_remote_method(session_id, record, remote_method_name)
          return unless session_id
          object_string = "HRPS__#{record.class}__#{record.id}__remote_method__#{remote_method_name}"
          Hyperstack::Transport::ServerPubSub.subscribe(object_string, session_id)
        end

        def subscribe_scope(session_id, collection, record_class = nil, scope_name = nil)
          return unless session_id
          object_strings = []

          if collection.is_a?(Enumerable)
            collection.each do |record|
              object_strings << "HRPS__#{record.class}__#{record.id}"
            end
          end
          object_strings <<  "HRPS__#{record_class}__scope__#{scope_name}" if record_class && scope_name
          Hyperstack::Transport::ServerPubSub.subscribe_to_many(object_strings, session_id)
        end

        def pub_sub_record(session_id, record)
          subscribe_record(session_id, record)
          publish_record(record)
        end

        def pub_sub_relation(session_id, relation, base_record, relation_name, causing_record = nil)
          subscribe_relation(session_id, relation, base_record, relation_name)
          publish_relation(base_record, relation_name, causing_record)
        end

        def pub_sub_rest_class_method(session_id, record_class, rest_class_method_name)
          subscribe_rest_class_method(session_id, record_class, rest_class_method_name)
          publish_rest_class_method(record_class, rest_class_method_name)
        end

        def pub_sub_remote_method(session_id, record, remote_method_name)
          subscribe_remote_method(session_id, record, remote_method_name)
          publish_remote_method(record, remote_method_name)
        end

        def pub_sub_scope(session_id, collection, record_class, scope_name)
          subscribe_scope(session_id, collection, record_class, scope_name)
          publish_scope(record_class, scope_name)
        end
      end
    end
  end
end
