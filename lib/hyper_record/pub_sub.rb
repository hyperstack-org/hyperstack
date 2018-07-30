module HyperRecord
  module PubSub
    def self.included(base)
      attr_accessor :policy_params

      base.extend(HyperRecord::PubSub::ClassMethods)
    end

    module ClassMethods
      attr_accessor :policy_params

      # @private
      def _pusher_client
        Hyperloop.pusher_instance ||= Pusher::Client.new(
          app_id: Hyperloop.pusher[:app_id],
          key: Hyperloop.pusher[:key],
          secret: Hyperloop.pusher[:secret],
          cluster: Hyperloop.pusher[:cluster]
        )
      end

      # send message about record change to all subscribers of this record
      #
      # @param record of ORM specific type, record must respond to: id, updated_at, destroyed?
      def publish_record(record)
        subscribers = Hyperloop.redis_instance.hgetall("HRPS__#{record.class}__#{record.id}")
        time_now = Time.now.to_f
        scrub_time = time_now - 24.hours.to_f

        message = if record.destroyed?
                    { record.class.to_s.underscore => { instances: { record.id => { destroyed: true }}}}
                  else
                    { record.class.to_s.underscore => { instances: { record.id => { properties: { updated_at: record.updated_at }}}}}
                  end

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
            _pusher_client.trigger_async(channel_array, 'update', message)
          elsif Hyperloop.resource_transport == :action_cable
            channel_array.each do |channel|
              ActionCable.server.broadcast(channel, message)
            end
          end
        end
        Hyperloop.redis_instance.del("HRPS__#{record.class}__#{record.id}") if record.destroyed?
      end

      # send message about relation change to all subscribers of this record
      #
      # @param base_record of ORM specific type, base_record must respond to: id, updated_at, destroyed?
      # @param relation_name [String]
      # @param record of ORM specific type, the record who causes the change, record must respond to: id, updated_at, destroyed?
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
            _pusher_client.trigger_async(channel_array, 'update', message)
          elsif Hyperloop.resource_transport == :action_cable
            channel_array.each do |channel|
              ActionCable.server.broadcast(channel, message)
            end
          end
        end
      end

      # send message to notify clients that they should call the rest_class_method again
      #
      # @param record_class ORM specific
      # @param rest_class_method_name [String]
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
            _pusher_client.trigger_async(channel_array, 'update', message)
          elsif Hyperloop.resource_transport == :action_cable
            channel_array.each do |channel|
              ActionCable.server.broadcast(channel, message)
            end
          end
        end
      end

      # send message to notify clients that they should call the rest_method again
      #
      # @param record of ORM specific type
      # @param rest_method_name [String]
      def publish_rest_method(record, rest_method_name)
        subscribers = Hyperloop.redis_instance.hgetall("HRPS__#{record.class}__#{record.id}__rest_method__#{rest_method_name}")
        time_now = Time.now.to_f
        scrub_time = time_now - 24.hours.to_f
        message = {
          record_type: record.class.to_s,
          id: record.id,
          rest_method: rest_method_name
        }
        subscribers.each_slice(10) do |slice|
          channel_array = []
          slice.each do |session_id, last_requested|
            if last_requested.to_f < scrub_time
              Hyperloop.redis_instance.hdel("HRPS__#{record.class}__#{record.id}__rest_method__#{rest_method_name}", session_id)
              next
            end
            channel_array << "hyper-record-update-channel-#{session_id}"
          end
          if Hyperloop.resource_transport == :pusher
            _pusher_client.trigger_async(channel_array, 'update', message)
          elsif Hyperloop.resource_transport == :action_cable
            channel_array.each do |channel|
              ActionCable.server.broadcast(channel, message)
            end
          end
        end
      end

      # send message about scope change to all subscribers
      #
      # @param record_class ORM specific
      # @param scope_name [String]
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
            _pusher_client.trigger_async(channel_array, 'update', message)
          elsif Hyperloop.resource_transport == :action_cable
            channel_array.each do |channel|
              ActionCable.server.broadcast(channel, message)
            end
          end
        end
      end

      # subscribe to record changes
      #
      # @param record of ORM specific type
      def subscribe_record(record)
        return unless session.id
        Hyperloop.redis_instance.hset "HRPS__#{record.class}__#{record.id}", session.id.to_s, Time.now.to_f.to_s
      end

      # subscribe to relation changes
      #
      # @param relation [Enumarable] or record of ORM specific type, subscribe to each member of relation
      # @param base_record optional, of ORM specific type, subscribe to this base_record too
      # @param relation_name [String] optional name of the relation
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

      # subscribe to rest_class_method updates
      #
      # @param record_class ORM specific
      # @param rest_class_method_name [String] name of the rest_class_method
      def subscribe_rest_class_method(record_class, rest_class_method_name)
        return unless session.id
        time_now = Time.now.to_f.to_s
        session_id = session.id.to_s
        Hyperloop.redis_instance.pipelined do
          Hyperloop.redis_instance.hset("HRPS__#{record_class}__rest_class_method_name__#{rest_class_method_name}", session_id, time_now)
        end
      end

      # subscribe to rest_method updates
      #
      # @param record of ORM specific type
      # @param rest_method_name [String] name of the rest_method
      def subscribe_rest_method(record, rest_method_name)
        return unless session.id
        time_now = Time.now.to_f.to_s
        session_id = session.id.to_s
        Hyperloop.redis_instance.hset("HRPS__#{record.class}__#{record.id}__rest_method__#{rest_method_name}", session_id, time_now)
      end

      # subscribe to scope updates
      #
      # @param collection [Enumerable] subscribe to each member of collection
      # @param record_class optional, ORM specific
      # @param scope_name [String] optional
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

      # subscribe to record and then publish
      #
      # @param record of ORM psecific type
      def pub_sub_record(record)
        subscribe_record(record)
        publish_record(record)
      end

      # subscribe to relation changes and then publish them
      #
      # @param relation [Enumarable] or record of ORM specific type, subscribe to each member of relation
      # @param base_record of ORM specific type, base_record must respond to: id, updated_at, destroyed?
      # @param relation_name [String]
      # @param causing_record of ORM specific type the record who causes the change, reacord must respond to: id, updated_at, destroyed?
      def pub_sub_relation(relation, base_record, relation_name, causing_record = nil)
        subscribe_relation(relation, base_record, relation_name)
        publish_relation(base_record, relation_name, causing_record)
      end

      # subscribe to rest_class_method and then send message to notify clients that
      # they should call the rest_class_method again
      #
      # @param record_class ORM specific
      # @param rest_class_method_name [String]
      def pub_sub_rest_class_method(record_class, rest_class_method_name)
        subscribe_rest_class_method(record_class, rest_class_method_name)
        publish_rest_class_method(record_class, rest_class_method_name)
      end

      # subscribe to rest_method and then send message to notify clients that
      # they should call the rest_method again
      #
      # @param record of ORM specific type
      # @param rest_method_name [String]
      def pub_sub_rest_method(record, rest_method_name)
        subscribe_rest_method(record, rest_method_name)
        publish_rest_method(record, rest_method_name)
      end

      # subscribe to scope changes and send message about scope change to all subscribers
      #
      # @param collection [Enumerable] subscribe to each member of collection
      # @param record_class ORM specific
      # @param scope_name [String]
      def pub_sub_scope(collection, record_class, scope_name)
        subscribe_scope(collection, record_class, scope_name)
        publish_scope(record_class, scope_name)
      end

      # @private
      def session
        @_hyper_resource_session
      end
    end

    # (see ClassMethods#publish_record)
    def publish_record(record)
      self.class.publish_record(record)
    end

    # (see ClassMethods#publish_relation)
    def publish_relation(base_record, relation_name, record = nil)
      self.class.publish_relation(base_record, relation_name, record)
    end

    # (see ClassMethods#publish_rest_class_method)
    def publish_rest_class_method(record_class, rest_class_method_name)
      self.class.publish_rest_class_method(record_class, rest_class_method_name)
    end

    # (see ClassMethods#publish_rest_method)
    def publish_rest_method(record, rest_method_name)
      self.class.publish_rest_method(record, rest_method_name)
    end

    # (see ClassMethods#publish_scope)
    def publish_scope(record_class, scope_name)
      self.class.publish_scope(record_class, scope_name)
    end

    # (see ClassMethods#subscribe_record)
    def subscribe_record(record)
      self.class.subscribe_record(record)
    end

    # (see ClassMethods#subscribe_relation)
    def subscribe_relation(relation, base_record = nil, relation_name = nil)
      self.class.subscribe_relation(relation, base_record, relation_name)
    end

    # (see ClassMethods#subscribe_rest_class_method)
    def subscribe_rest_class_method(record_class, rest_class_method_name)
      self.class.subscribe_rest_class_method(record_class, rest_class_method_name)
    end

    # (see ClassMethods#subscribe_rest_method)
    def subscribe_rest_method(record, rest_method_name)
      self.class.subscribe_rest_method(record, rest_method_name)
    end

    # (see ClassMethods#subscribe_scope)
    def subscribe_scope(collection, record_class = nil, scope_name = nil)
      self.class.subscribe_scope(collection, record_class, scope_name)
    end

    # (see ClassMethods#pub_sub_record)
    def pub_sub_record(record)
      self.class.pub_sub_record(record)
    end

    # (see ClassMethods#pub_sub_relation)
    def pub_sub_relation(relation, base_record, relation_name, causing_record = nil)
      self.class.pub_sub_relation(relation, base_record, relation_name, causing_record)
    end

    # (see ClassMethods#pub_sub_rest_class_method)
    def pub_sub_rest_class_method(record_class, rest_class_method_name)
      self.class.pub_sub_rest_class_method(record_class, rest_class_method_name)
    end

    # (see ClassMethods#pub_sub_rest_method)
    def pub_sub_rest_method(record, rest_method_name)
      self.class.pub_sub_rest_method(record, rest_method_name)
    end

    # (see ClassMethods#pub_sub_scope)
    def pub_sub_scope(collection, record_class, scope_name)
      self.class.pub_sub_scope(collection, record_class, scope_name)
    end
  end
end
