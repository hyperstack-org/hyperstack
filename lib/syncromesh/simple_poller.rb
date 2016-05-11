module Syncromesh
  module SimplePoller

    require "pstore"

    def self.subscribe
      subscriber = SecureRandom.hex(10)
      update_store do |store|
        store[subscriber] = {data: [], last_read_at: Time.now}
      end
      subscriber
    end

    def self.read(subscriber)
      update_store do |store|
        data = store[subscriber][:data] rescue []
        store[subscriber] = {data: [], last_read_at: Time.now}
        data
      end
    end

    def self.write(event, data)
      update_store do |store|
        store.each do |subscriber, subscriber_store|
          subscriber_store[:data] << [event, data]
        end
      end

    end

    def self.update_store
      store = PStore.new('syncromesh-simple-poller-store')
      store.transaction do
        data = store[:data] || {}
        data.delete_if do |subscriber, subscriber_store|
          subscriber_store[:last_read_at] < Time.now-Syncromesh.seconds_polled_data_will_be_retained
        end
        result = yield data
        store[:data] = data
        result
      end
    end
  end

end
