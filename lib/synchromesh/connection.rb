module Synchromesh
  class Connection

    # get list of current active channels
    # write data to a channel
    # read data from a channel-session pair
    # add a new channel-session pair
    # activate a channel-session pair

    # self.transport = ... object that responds to expire_new_connection_in, expire_polled_connection_in, refresh, refresh_in

    # life cycle
    # self.new(channel, session) - add a new channel for a session
    # self.write data to channel
    # FOR POLLED CONNECTIONS
    #   self.read data for session
    #   self.write data to channel
    #   ...repeat
    # FOR other transports
    #   self.connect_transport(session, channel
    #
    #
    # externally ask for all active_channels
    # which may execute a callback to renew_connections

    class << self

      # this must be assigned to before creating any new connections.
      # the object assigned to transport must repond to the following method:
      # #expire_new_connection_in
      # In addition if the connection will be polled the transport object must
      # respond ot #expire_polled_connection_in
      # If the connection will be connected to a non-polled transport (pusher, actioncable)
      # the object must respond to #refresh (which will return a list of current connections) and
      # #refresh_in (time to next refresh)

      attr_accessor :transport

      STORE_ID = :synchromesh_active_connections

      def active
        connections = fetch_connections.delete_if do |connection|
          refresh if connection.refresh_at && connection.refresh_at < Time.now
          connection.expires_at && connection.expires_at < Time.now
        end
        update_connections connections
        connections.collect { |connection| connection.channel }.uniq
      end

      alias _new new

      def new(channel, session)
        connect_with_connections channel, session, fetch_connections, false
      end

      def send(channel, data)
        active_transport_connections = false
        connections = fetch_connections
        connections.each do |connection|
          if connection.session
            connection.messages << data if connection.channel == channel
          else
            active_transport_connections ||= true
          end
        end
        update_connections connections
        transport.send(channel, data) if active_transport_connections
      end

      def read(session)
        connections = fetch_connections
        messages = connections.collect do |connection|
          next if connection.session != session
          connection.expires_at = Time.now + transport.expire_polled_connection_in
          connection.read_messages
        end.compact.flatten(1)
        update_connections connections
        messages
      end

      def connect_to_transport(channel, session)
        messages = []
        connections = fetch_connections.delete_if do |connection|
          if connection.is_for?(channel, session)
            messages += connection.messages
          end
        end
        connect_with_connections(channel, nil, connections, true)
        messages
      end

      def disconnect(channel)
        update_connections fetch_connections.delete_if { |c| c.is_fo?(channel, nil) }
      end

      # private

      def fetch_connections
        Rails.cache.fetch(STORE_ID) { [] }
      end

      def update_connections(connections)
        Rails.cache.write(STORE_ID, connections)
      end

      def refresh
        return if @refreshing
        @refreshing = true
        Thread.new do
          begin
            Timeout::timeout(transport.refresh_channels_timeout) do
              update_connections merge_refreshed_channels
            end
          ensure
            @refreshing = false
          end
        end
      end

      def merge_refreshed_channels
        refresh_time = Time.now
        channels = transport.refresh_channels
        connections = fetch_connections
        connections.delete_if do |connection|
          next false if connection.session
          next false if connection.updated_at > refresh_time
          next true unless channels.include?(connection.channel)
          connection.refresh_at = Time.now + transport.refresh_channels_every
          false
        end
      end

      def connect_with_connections(channel, session, connections, save)
        connection = connections.detect do |connection|
          connection.is_for?(channel, session)
        end
        if connection
          update_connections connections if save
        else
          connection = _new(channel, session)
          update_connections connections << connection
        end
        connection
      end

    end

    attr_accessor :channel
    attr_accessor :session
    attr_accessor :updated_at
    attr_accessor :expires_at
    attr_accessor :refresh_at
    attr_accessor :messages

    def initialize(channel, session)
      @updated_at = Time.now
      @channel = channel
      if session
        @session = session
        @expires_at = Time.now + transport.expire_new_connection_in
        @messages = []
      elsif transport.refresh_channels_every
        @refresh_at = Time.now + transport.refresh_channels_every
      end
    end

    def transport
      self.class.transport
    end

    def read_messages
      messages.tap { self.messages = [] }
    end

    def is_for?(channel, session)
      self.channel == channel && self.session == session
    end

  end
end
