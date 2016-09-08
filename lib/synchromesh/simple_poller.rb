module Synchromesh
  # Simple polling transport
  # Keeps track of subscribers in the ruby pstore
  # Each subscriber has a queue of messages that will be returned
  # when the subscriber polls the server.  The last_read_at value
  # lets us close down subscribers who have gone away.

  class SimplePoller
    require 'pstore'

    class << self

      def channels
        @channels ||= Hash.new { |h, k| h[k] = SimplePoller.new(k) }
      end

      def subscriptions
        @subscriptions ||= Hash.new { |h, k| h[k] = [] }
      end

      def subscribe(session_id, acting_user, channel)
        Synchromesh::InternalPolicy.regulate_connection(acting_user, channel)
        channels[channel].update_store do |store|
          store[session_id] = { data: [], last_read_at: Time.now }
        end
        subscriptions[session_id] << channels[channel]
        Synchromesh::AutoConnect::PendingConnection.connected(session_id, channel)
      end

      def open_connections
        channels.collect do |channel, simple_poller|
          simple_poller.update_store do |store|
            channel unless store.empty?
          end
        end.compact
      end

      def read(session_id)
        subscriptions[session_id].collect do |channel|
          channel.update_store do |store|
            data = store[session_id][:data] rescue []
            store[session_id] = { data: [], last_read_at: Time.now }
            data
          end
        end.flatten(1)
      end

      def write(channel, event, data)
        channels[channel].update_store do |store|
          store.each_value do |subscriber_store|
            subscriber_store[:data] << [event, data]
          end
        end
      end
    end

    def initialize(channel)
      @channel = channel
    end

    def update_store
      stores = PStore.new("synchromesh-simple-poller-store")
      stores.transaction do
        store = (stores[@channel] ||= {})
        data = store[:data] || {}
        data.delete_if do |_subscriber, subscriber_store|
          expired?(subscriber_store)
        end
        result = yield data
        store[:data] = data
        result
      end
    end

    def expired?(subscriber_store)
      subscriber_store[:last_read_at] <
        (Time.now - Synchromesh.seconds_polled_data_will_be_retained)
    end
  end
end
