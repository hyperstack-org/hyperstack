module Hyperloop
  module Resource
    module PubSub
      def self.included(base)
        base.extend(Hyperloop::Resource::PubSub::ClassMethods)
      end

      module ClassMethods
        # @private
        def _pusher_client
          Hyperloop.pusher_instance ||= Pusher::Client.new(
            app_id: Hyperloop.pusher[:app_id],
            key: Hyperloop.pusher[:key],
            secret: Hyperloop.pusher[:secret],
            cluster: Hyperloop.pusher[:cluster]
          )
        end
      end

      # (see HyperRecord::ClassMethods#publish_record)
      def publish_record(record)
        subscribers = Hyperloop.redis_instance.hgetall("HRPS__#{record.class}__#{record.id}")
        time_now = Time.now.to_f
        scrub_time = time_now - 24.hours.to_f

        message = {
          record_type: record.class.to_s,
          id: record.id,
          updated_at: record.updated_at
        }
        message[:destroyed] = true if record.destroyed?

        # can only trigger max 10 channels at once on pusher
        subscribers.each_slice(10) do |slice|
          channel_array = []
          slice.each do |session_id, last_requested|
            if last_requested.to_f < scrub_time
              Hyperloop.redis_instance.hdel("HRPS__#{record.class}__#{record.id}", session_id)
              next
            end
            channel_array << "hyper-record-update-channel-#{session_id}"
          end
          return if channel_array.size == 0
          if Hyperloop.resource_transport == :pusher
            self.class._pusher_client.trigger_async(channel_array, 'update', message)
          elsif Hyperloop.resource_transport == :action_cable
            channel_array.each do |channel|
              ActionCable.server.broadcast(channel, message)
            end
          end
        end
        Hyperloop.redis_instance.del("HRPS__#{record.class}__#{record.id}") if record.destroyed?
      end

      def publish_relation(base_record, relation_name, record = nil)
        subscribers = Hyperloop.redis_instance.hgetall("HRPS__#{base_record.class}__#{base_record.id}__#{relation_name}")
        time_now = Time.now.to_f
        scrub_time = time_now - 24.hours.to_f
        message = {
          record_type: base_record.class.to_s,
          id: base_record.id,
          updated_at: base_record.updated_at,
          relation: relation_name
        }
        if record
          message[:cause] = {}
          message[:cause][:record_type] = record.class.to_s
          message[:cause][:id] = record.id
          message[:cause][:updated_at] = record.updated_at
          message[:cause][:destroyed] = true if record.destroyed?
        end
        subscribers.each_slice(10) do |slice|
          channel_array = []
          slice.each do |session_id, last_requested|
            if last_requested.to_f < scrub_time
              Hyperloop.redis_instance.hdel("HRPS__#{base_record.class}__#{base_record.id}__#{relation_name}", session_id)
              next
            end
            channel_array << "hyper-record-update-channel-#{session_id}"
          end
          if Hyperloop.resource_transport == :pusher
            self.class._pusher_client.trigger_async(channel_array, 'update', message)
          elsif Hyperloop.resource_transport == :action_cable
            channel_array.each do |channel|
              ActionCable.server.broadcast(channel, message)
            end
          end
        end
      end

      def publish_rest_class_method(record_class, rest_class_method_name)
        subscribers = Hyperloop.redis_instance.hgetall("HRPS__#{record_class}__rest_class_method__#{rest_class_method_name}")
        time_now = Time.now.to_f
        scrub_time = time_now - 24.hours.to_f
        message = {
          record_type: record_class.to_s,
          rest_class_method: rest_class_method_name
        }
        subscribers.each_slice(10) do |slice|
          channel_array = []
          slice.each do |session_id, last_requested|
            if last_requested.to_f < scrub_time
              Hyperloop.redis_instance.hdel("HRPS__#{record_class}__rest_class_method__#{rest_class_method_name}", session_id)
              next
            end
            channel_array << "hyper-record-update-channel-#{session_id}"
          end
          if Hyperloop.resource_transport == :pusher
            self.class._pusher_client.trigger_async(channel_array, 'update', message)
          elsif Hyperloop.resource_transport == :action_cable
            channel_array.each do |channel|
              ActionCable.server.broadcast(channel, message)
            end
          end
        end
      end

      def publish_rest_method(record, method_name)
        subscribers = Hyperloop.redis_instance.hgetall("HRPS__#{record.class}__#{record.id}__rest_method__#{method_name}")
        time_now = Time.now.to_f
        scrub_time = time_now - 24.hours.to_f
        message = {
          record_type: record.class.to_s,
          id: record.id,
          rest_method: method_name
        }
        subscribers.each_slice(10) do |slice|
          channel_array = []
          slice.each do |session_id, last_requested|
            if last_requested.to_f < scrub_time
              Hyperloop.redis_instance.hdel("HRPS__#{record.class}__#{record.id}__rest_method__#{method_name}", session_id)
              next
            end
            channel_array << "hyper-record-update-channel-#{session_id}"
          end
          if Hyperloop.resource_transport == :pusher
            self.class._pusher_client.trigger_async(channel_array, 'update', message)
          elsif Hyperloop.resource_transport == :action_cable
            channel_array.each do |channel|
              ActionCable.server.broadcast(channel, message)
            end
          end
        end
      end

      def publish_scope(record_class, scope_name)
        subscribers = Hyperloop.redis_instance.hgetall("HRPS__#{record_class}__scope__#{scope_name}")
        time_now = Time.now.to_f
        scrub_time = time_now - 24.hours.to_f
        message = {
          record_type: record_class.to_s,
          scope: scope_name
        }
        subscribers.each_slice(10) do |slice|
          channel_array = []
          slice.each do |session_id, last_requested|
            if last_requested.to_f < scrub_time
              Hyperloop.redis_instance.hdel("HRPS__#{record_class}__scope__#{scope_name}", session_id)
              next
            end
            channel_array << "hyper-record-update-channel-#{session_id}"
          end
          if Hyperloop.resource_transport == :pusher
            self.class._pusher_client.trigger_async(channel_array, 'update', message)
          elsif Hyperloop.resource_transport == :action_cable
            channel_array.each do |channel|
              ActionCable.server.broadcast(channel, message)
            end
          end
        end
      end

      def subscribe_record(record)
        return unless session.id
        Hyperloop.redis_instance.hset "HRPS__#{record.class}__#{record.id}", session.id.to_s, Time.now.to_f.to_s
      end

      def subscribe_relation(relation, base_record = nil, relation_name = nil)
        return unless session.id
        time_now = Time.now.to_f.to_s
        session_id = session.id.to_s
        Hyperloop.redis_instance.pipelined do
          if relation.is_a?(Enumerable)
            # has_many
            relation.each do |record|
              Hyperloop.redis_instance.hset("HRPS__#{record.class}__#{record.id}", session_id, time_now)
            end
          elsif !relation.nil?
            # has_one, belongs_to
            Hyperloop.redis_instance.hset("HRPS__#{relation.class}__#{relation.id}", session_id, time_now)
          end
          Hyperloop.redis_instance.hset("HRPS__#{base_record.class}__#{base_record.id}__#{relation_name}", session_id, time_now) if base_record && relation_name
        end
      end

      def subscribe_rest_class_method(record_class, rest_class_method_name)
        return unless session.id
        time_now = Time.now.to_f.to_s
        session_id = session.id.to_s
        Hyperloop.redis_instance.pipelined do
          Hyperloop.redis_instance.hset("HRPS__#{record_class}__rest_class_method_name__#{rest_class_method_name}", session_id, time_now)
        end
      end

      def subscribe_rest_method(record, rest_method_name)
        return unless session.id
        time_now = Time.now.to_f.to_s
        session_id = session.id.to_s
        Hyperloop.redis_instance.hset("HRPS__#{record.class}__#{record.id}__rest_method__#{rest_method_name}", session_id, time_now)
      end

      def subscribe_scope(collection, record_class = nil, scope_name = nil)
        return unless session.id
        time_now = Time.now.to_f.to_s
        session_id = session.id.to_s
        Hyperloop.redis_instance.pipelined do
          if collection.is_a?(Enumerable)
            collection.each do |record|
              Hyperloop.redis_instance.hset("HRPS__#{record.class}__#{record.id}", session_id, time_now)
            end
          end
          Hyperloop.redis_instance.hset("HRPS__#{record_class}__scope__#{scope_name}", session_id, time_now) if record_class && scope_name
        end
      end

      def pub_sub_record(record)
        subscribe_record(record)
        publish_record(record)
      end

      def pub_sub_relation(relation, base_record, relation_name, causing_record = nil)
        subscribe_relation(relation, base_record, relation_name)
        publish_relation(base_record, relation_name, causing_record)
      end

      def pub_sub_rest_class_method(record_class, rest_class_method_name)
        subscribe_rest_class_method(record_class, rest_class_method_name)
        publish_rest_class_method(record_class, rest_class_method_name)
      end

      def pub_sub_rest_method(record, rest_method_name)
        subscribe_rest_method(record, rest_method_name)
        publish_rest_method(record, rest_method_name)
      end

      def pub_sub_scope(collection, record_class, scope_name)
        subscribe_scope(collection, record_class, scope_name)
        publish_scope(record_class, scope_name)
      end
    end
  end
end
