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
        @subscriptions ||= []
      end

      def subscribe(session_id, acting_user, channel)
        Synchromesh::InternalPolicy.regulate_connection(acting_user, channel)
        channels[channel].update_store do |store|
          store[session_id] = { data: [], last_read_at: Time.now }
        end
        subscriptions[session_id] << channels[channel]
      end

      def read(session_id)
        subscriptions[session_id].inject({}) do |h, channel|
          h[channel] = channel.update_store do |store|
            data = store[session_id][:data] rescue []
            store[session_id] = { data: [], last_read_at: Time.now }
            data
          end
        end
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
      store = PStore.new("synchromesh-simple-poller-store-#{@channel}")
      store.transaction do
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
