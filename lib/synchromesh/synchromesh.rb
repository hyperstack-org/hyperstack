require 'synchromesh/configuration'
# Provides the configuration and the two basic routines for the server
# to indicate that records have changed: after_change and after_destroy
module Synchromesh


  extend Configuration

  def self.config_reset
    @pusher = nil
  end

  define_setting :transport, :none
  define_setting :opts, {}
  define_setting :channel_prefix
  define_setting :client_logging, true

  def self.app_id
    opts[:app_id] || Pusher.app_id if transport == :pusher
  end

  def self.key
    opts[:key] || Pusher.key if transport == :pusher
  end

  def self.secret
    opts[:secret] || Pusher.secret if transport == :pusher
  end

  def self.encrypted
    opts.key?(:encrypted) ? opts[:encrypted] : true
  end

  def self.seconds_polled_data_will_be_retained
    opts[:seconds_polled_data_will_be_retained] || (5 * 60)
  end

  def self.seconds_between_poll
    opts[:seconds_between_poll] || 0.5
  end

  def self.autoconnect_timeout
    opts[:autoconnect_timeout] || 10.seconds
  end

  def self.pusher
    unless @pusher
      unless channel_prefix
        self.transport = nil
        raise '******** NO CHANNEL PREFIX SET ***************'
      end
      @pusher = Pusher::Client.new(
        opts || { app_id: app_id, key: key, secret: secret }
      )
    end
    @pusher
  end

  def self.channel
    "private-#{channel_prefix}"
  end

  def self.after_change(model)
    InternalPolicy.regulate_broadcast(model) do |data|
      send_to_transport('change', data)
    end
  end

  def self.after_destroy(model)
    InternalPolicy.regulate_broadcast(model) do |data|
      send_to_transport('destroy', data)
    end
  end

  def self.send_to_transport(message, data)
    PolledConnection.write [message, data]
    case transport
    when :pusher
      pusher.trigger("#{Synchromesh.channel}-#{data[:channel]}", message, data)
    else
      transport_error
    end
  end

  def self.transport_error
    unless [:none, :simple_poller].include? transport
      raise "Unknown transport #{Synchromesh.transport} - not supported"
    end
    []
  end

  def self.open_connections
    case transport
    when :pusher
      PusherChannels.open_connections
    else
      transport_error
    end + PolledConnection.open_connections
  end

  module XPusherChannels
    require 'pstore'

    STORE_ID = "synchromesh-pusher-channel-store"
    POLL_INTERVAL = 1.minute

    class << self

      def add_connection(channel)
        PStore.new(STORE_ID).transaction do |store|
          store[:last_update] ||= Time.now
          (store[:connections] ||= Set.new) << channel
        end
      end

      def open_connections
        PStore.new(STORE_ID).transaction do |store|
          store[:last_update] = update_connections(store[:last_update])
          store[:connections] || []
        end
      end

      def update_connections(last_update)
        return last_update if last_update && last_update >= Time.now-POLL_INTERVAL
        Thread.new do
          Timeout::timeout(5) do
            connections = Synchromesh.pusher.channels[:channels].collect do |channel|
              channel.gsub(/^#{Regexp.quote(Synchromesh.channel)}/,'')
            end.uniq
            PStore.new(STORE_ID).transaction do |store|
              store[:connections] = connections
              store[:last_update] = Time.now
            end
          end
        end
        Time.now-POLL_INTERVAL+5
      end
    end
  end

  module PusherChannels

    STORE_ID = "synchromesh-pusher-channel-store"
    POLL_INTERVAL = 1.minute
    TIME_OUT = 5.seconds

    class << self

      def add_connection(channel)
        connections = read_connections
        connections[channel] = Time.now
        Rails.cache.write(STORE_ID, connections)
      end

      def open_connections
        oldest_update = newest_update = Time.at(0)
        connections = read_connections.collect do |connection, updated_at|
          oldest_update = [oldest_update, updated_at].min
          newest_update = [newest_update, updated_at].max
          connection
        end
        update_connections_before(newest_update) if oldest_update < Time.now-POLL_INTERVAL
        connections
      end

      def read_connections
        Rails.cache.fetch(STORE_ID) do
          {}
        end
      end

      def current_channels(newest_update)
        new_channels = Synchromesh.pusher.channels[:channels].collect do |channel|
          channel.gsub(/^#{Regexp.quote(Synchromesh.channel)}/,'')
        end.map { |channel| [channel, Time.now] }.to_h
        read_connections.delete_if do |connection, updated_at|
          updated_at <= newest_update
        end.merge(new_channels)
      end

      def update_connections_before(newest_update)
        Thread.new do
          Timeout::timeout(TIME_OUT) do
            Rails.cache.write(STORE_ID, current_channels(newest_update))
          end
        end
      end
    end
  end

end
