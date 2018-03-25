module Hyperloop
  module Resource
    module PubSub
      def self.included(base)
        base.extend(Hyperloop::Resource::PubSub::ClassMethods)
      end

      module ClassMethods
        def _pusher_client
          @pusher_client ||= Pusher::Client.new(
            app_id: Hyperloop.pusher[:app_id],
            key: Hyperloop.pusher[:key],
            secret: Hyperloop.pusher[:secret],
            cluster: Hyperloop.pusher[:cluster]
          )
        end
      end

      def publish_collection(baserecord, collection_name, record = nil)
        subscribers = $redis.hgetall("HRPS__#{baserecord.class}__#{baserecord.id}__#{collection_name}")
        time_now = Time.now.to_f
        scrub_time = time_now - 24.hours.to_f
        message = {
          record_type: baserecord.class.to_s,
          id: baserecord.id,
          updated_at: baserecord.updated_at,
          collection: collection_name
        }
        if record
          message[:cause] = {}
          message[:cause][:record_type] = record.class.to_s
          message[:cause][:id] = record.id
          message[:cause][:updated_at] = record.updated_at
        end
        subscribers.each do |session_id, last_requested|
          if last_requested.to_f < scrub_time
            $redis.hdel("HRPS__#{baserecord.class}__#{baserecord.id}__#{collection_name}", session_id)
            next
          end
          if Hyperloop.resource_transport == :pusher
            self.class._pusher_client.trigger("hyper-record-update-channel-#{session_id}", 'update', message)
          end
        end
      end

      def publish_record(record)
        subscribers = $redis.hgetall("HRPS__#{record.class}__#{record.id}")
        time_now = Time.now.to_f
        scrub_time = time_now - 24.hours.to_f
        
        message = {
          record_type: record.class.to_s,
          id: record.id,
          updated_at: record.updated_at
        }
        message[:destroyed] = true if record.destroyed?
    
        subscribers.each_slice(50) do |slice|
          channel_array= []
          slice.each do |session_id, last_requested|
            if last_requested.to_f < scrub_time
              $redis.hdel("HRPS__#{record.class}__#{record.id}", session_id)
              next
            end
            channel_array << "hyper-record-update-channel-#{session_id}"
          end
          if Hyperloop.resource_transport == :pusher && channel_array.size > 0
            self.class._pusher_client.trigger(channel_array, 'update', message)
          end
        end
        $redis.del("HRPS__#{record.class}__#{record.id}") if record.destroyed?
      end
    
      def publish_scope(klass, scope_name)
        subscribers = $redis.hgetall("HRPS__#{klass}__scope__#{scope_name}")
        time_now = Time.now.to_f
        scrub_time = time_now - 24.hours.to_f
        subscribers.each do |session_id, last_requested|
          if last_requested.to_f < scrub_time
            $redis.hdel("HRPS__#{klass}__scope__#{scope_name}", session_id)
            next
          end
          message = {
            record_type: klass.to_s,
            scope: scope_name
          }
          if Hyperloop.resource_transport == :pusher
            self.class._pusher_client.trigger("hyper-record-update-channel-#{session_id}", 'update', message)
          end
        end
      end

      def subscribe_collection(collection, baserecord = nil, collection_name = nil)
        return unless session.id
        time_now = Time.now.to_f.to_s
        session_id = session.id.to_s
        $redis.pipelined do
          if collection.is_a?(Enumerable)
            # has_many
            collection.each do |record|
              $redis.hset("HRPS__#{record.class}__#{record.id}", session_id, time_now)
            end
          else
            # has_one, belongs_to
            $redis.hset("HRPS__#{collection.class}__#{collection.id}", session_id, time_now)
          end
          $redis.hset("HRPS__#{baserecord.class}__#{baserecord.id}__#{collection_name}", session_id, time_now) if baserecord && collection_name
        end
      end
    
      def subscribe_record(record)
        return unless session.id
        $redis.hset "HRPS__#{record.class}__#{record.id}", session.id.to_s, Time.now.to_f.to_s
      end
    
      def subscribe_scope(collection, klass = nil, scope_name = nil)
        return unless session.id
        time_now = Time.now.to_f.to_s
        session_id = session.id.to_s
        $redis.pipelined do
          if collection.is_a?(Enumerable)
            collection.each do |record|
              $redis.hset("HRPS__#{record.class}__#{record.id}", session_id, time_now)
            end
          end
          $redis.hset("HRPS__#{klass}__scope__#{scope_name}", session_id, time_now) if klass && scope_name
        end
      end
    
      def pub_sub_collection(collection, baserecord, collection_name, causing_record = nil)
        subscribe_collection(collection, baserecord, collection_name)
        publish_collection(baserecord, collection_name, causing_record)
      end
    
      def pub_sub_record(record)
        subscribe_record(record)
        publish_record(record)
      end
    
      def pub_sub_scope(collection, klass, scope_name)
        subscribe_scope(collection, klass, scope_name)
        publish_scope(klass, scope_name)
      end
    end
  end
end