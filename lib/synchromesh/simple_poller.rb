module Synchromesh
  # Simple polling transport
  # Keeps track of subscribers in the ruby pstore
  # Each subscriber has a queue of messages that will be returned
  # when the subscriber polls the server.  The last_read_at value
  # lets us close down subscribers who have gone away.
  module SimplePoller
    require 'pstore'

    def self.subscribe
      subscriber = SecureRandom.hex(10)
      update_store do |store|
        store[subscriber] = { data: [], last_read_at: Time.now }
      end
      subscriber
    end

    def self.read(subscriber)
      update_store do |store|
        data = store[subscriber][:data] rescue []
        store[subscriber] = { data: [], last_read_at: Time.now }
        data
      end
    end

    def self.write(event, data)
      update_store do |store|
        store.each_value do |subscriber_store|
          subscriber_store[:data] << [event, data]
        end
      end
    end

    def self.update_store
      store = PStore.new('synchromesh-simple-poller-store')
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

    def self.expired?(subscriber_store)
      subscriber_store[:last_read_at] <
        (Time.now - Synchromesh.seconds_polled_data_will_be_retained)
    end
  end
end
