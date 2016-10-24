module Synchromesh
  class Connection < ActiveRecord::Base
    class QueuedMessage < ActiveRecord::Base
      self.table_name = 'synchromesh_queued_messages'

      do_not_synchronize

      serialize :data

      belongs_to :synchromesh_connection,
                 class_name: 'Synchromesh::Connection',
                 foreign_key: 'connection_id'

      scope :for_session,
            ->(session) { joins(:synchromesh_connection).where('session = ?', session) }

      # For simplicity we use QueuedMessage with connection_id 0
      # to store the current path which is used by consoles to
      # communicate back to the server

      default_scope { where('connection_id IS NULL OR connection_id != 0') }

      def self.root_path=(path)
        unscoped.find_or_create_by(connection_id: 0).update(data: path)
      end

      def self.root_path
        unscoped.find_or_create_by(connection_id: 0).data
      end
    end

    def self.build_tables
      # unless connection.tables.include? 'synchromesh_connections'
      connection.create_table(:synchromesh_connections, force: true) do |t|
        t.string   :channel
        t.string   :session
        t.datetime :created_at
        t.datetime :expires_at
        t.datetime :refresh_at
      end
      # unless connection.tables.include? 'synchromesh_queued_messages'
      connection.create_table(:synchromesh_queued_messages, force: true) do |t|
        t.text    :data
        t.integer :connection_id
      end
    end

    do_not_synchronize

    self.table_name = 'synchromesh_connections'

    has_many :messages,
             foreign_key: 'connection_id',
             class_name: 'Synchromesh::Connection::QueuedMessage',
             dependent: :destroy
    scope :expired,
          -> { where('expires_at IS NOT NULL AND expires_at < ?', Time.zone.now) }
    scope :pending_for,
          ->(channel) { where(channel: channel).where('session IS NOT NULL') }
    scope :inactive,
          -> { where('session IS NULL AND refresh_at < ?', Time.zone.now) }

    def self.needs_refresh?
      exists?(['refresh_at IS NOT NULL AND refresh_at < ?', Time.zone.now])
    end

    def transport
      self.class.transport
    end

    before_create do
      if session
        self.expires_at = Time.now + transport.expire_new_connection_in
      elsif transport.refresh_channels_every != :never
        self.refresh_at = Time.now + transport.refresh_channels_every
      end
    end

    class << self
      attr_accessor :transport

      def active
        expired.delete_all
        refresh_connections if needs_refresh?
        all.pluck(:channel).uniq
      end

      def open(channel, session = nil, root_path = nil)
        self.root_path = root_path
        find_or_create_by(channel: channel, session: session)
      end

      def send_to_channel(channel, data)
        pending_for(channel).each do |connection|
          QueuedMessage.create(data: data, synchromesh_connection: connection)
        end
        transport.send(channel, data) if exists?(channel: channel, session: nil)
      end

      def read(session, root_path)
        self.root_path = root_path
        where(session: session)
          .update_all(expires_at: Time.now + transport.expire_polled_connection_in)
        QueuedMessage.for_session(session).destroy_all.pluck(:data)
      end

      def connect_to_transport(channel, session, root_path)
        self.root_path = root_path
        if (connection = find_by(channel: channel, session: session))
          messages = connection.messages.pluck(:data)
          connection.destroy
        else
          messages = []
        end
        open(channel)
        messages
      end

      def disconnect(channel)
        find_by(channel: channel, session: nil).destroy
      end

      def root_path=(path)
        QueuedMessage.root_path = path if path
      end

      def root_path
        QueuedMessage.root_path
      end

      def refresh_connections
        refresh_started_at = Time.zone.now
        channels = transport.refresh_channels
        next_refresh = refresh_started_at + transport.refresh_channels_every
        channels.each do |channel|
          find_by(channel: channel, session: nil).update(refresh_at: next_refresh)
        end
        inactive.delete_all
      end
    end
  end
end

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

#     class << self
#
#
#       # this must be assigned to before creating any new connections.
#       # the object assigned to transport must repond to the following method:
#       # #expire_new_connection_in
#       # In addition if the connection will be polled the transport object must
#       # respond ot #expire_polled_connection_in
#       # If the connection will be connected to a non-polled transport (pusher, actioncable)
#       # the object must respond to #refresh (which will return a list of current connections) and
#       # #refresh_in (time to next refresh)
#
#       attr_accessor :transport
#
#       def active
#         connections = fetch_connections.delete_if do |connection|
#           refresh if connection.refresh_at && connection.refresh_at < Time.now
#           connection.expires_at && connection.expires_at < Time.now
#         end
#         update_connections connections
#         connections.collect { |connection| connection.channel }.uniq
#       end
#
#       #alias _new new
#
#       def open(channel, session)
#         connect_with_connections channel, session, fetch_connections, false
#       end
#
#       def sendx(channel, data)
#         active_transport_connections = false
#         connections = fetch_connections
#         connections.each do |connection|
#           if connection.session
#             connection.messages << data if connection.channel == channel
#           else
#             active_transport_connections ||= true
#           end
#         end
#         update_connections connections
#         transport.send(channel, data) if active_transport_connections
#       end
#
#       def read(session)
#         connections = fetch_connections
#         messages = connections.collect do |connection|
#           next if connection.session != session
#           connection.expires_at = Time.now + transport.expire_polled_connection_in
#           connection.read_messages
#         end.compact.flatten(1)
#         update_connections connections
#         messages
#       end
#
#       def connect_to_transport(channel, session, root_path)
#         self.root_path = root_path
#         messages = []
#         connections = fetch_connections.delete_if do |connection|
#           if connection.is_for?(channel, session)
#             messages += connection.messages
#           end
#         end
#         connect_with_connections(channel, nil, connections, true)
#         messages
#       end
#
#       def disconnect(channel)
#         update_connections fetch_connections.delete_if { |c| c.is_for?(channel, nil) }
#       end
#
#       def root_path=(path)
#         if path
#           Rails.cache.write("#{STORE_ID}-root-path", path)
#         else
#           Rails.cache.delete("#{STORE_ID}-root-path")
#         end
#       end
#
#       def root_path
#         Rails.cache.fetch("#{STORE_ID}-root-path") { nil }
#       end
#
#       # private
#
#       def fetch_connections
#         Rails.cache.fetch(STORE_ID) { [] }
#       end
#
#       def update_connections(connections)
#         Rails.cache.write(STORE_ID, connections)
#       end
#
#       def refresh
#         return if @refreshing || Synchromesh.on_console?
#         @refreshing = true
#         Thread.new do
#           begin
#             Timeout::timeout(transport.refresh_channels_timeout) do
#               update_connections merge_refreshed_channels
#             end
#           ensure
#             @refreshing = false
#           end
#         end
#       end
#
#       def merge_refreshed_channels
#         refresh_time = Time.now
#         channels = transport.refresh_channels
#         connections = fetch_connections
#         connections.delete_if do |connection|
#           next false if connection.session
#           next false if connection.updated_at > refresh_time
#           next true unless channels.include?(connection.channel)
#           connection.refresh_at = Time.now + transport.refresh_channels_every
#           false
#         end
#       end
#
#       def connect_with_connections(channel, session, connections, save)
#         connection = connections.detect do |connection|
#           connection.is_for?(channel, session)
#         end
#         if connection
#           update_connections connections if save
#         else
#           connection = _new(channel, session)
#           update_connections connections << connection
#         end
#         connection
#       end
#     end if false
#
#     # attr_accessor :channel
#     # attr_accessor :session
#     # attr_accessor :updated_at
#     # attr_accessor :expires_at
#     # attr_accessor :refresh_at
#     # attr_accessor :messages
#     #
#     # def xinitialize(channel, session, root_path = nil)
#     #   Connection.root_path = root_path if root_path
#     #   @updated_at = Time.now
#     #   @channel = channel
#     #   if session
#     #     @session = session
#     #     @expires_at = Time.now + transport.expire_new_connection_in
#     #     @messages = []
#     #   elsif transport.refresh_channels_every != :never
#     #     @refresh_at = Time.now + transport.refresh_channels_every
#     #   end
#     # end
#     #
#     # def transport
#     #   self.class.transport
#     # end
#     #
#     # def read_messages
#     #   messages.tap { self.messages = [] }
#     # end
#     #
#     # def is_for?(channel, session)
#     #   self.channel == channel && self.session == session
#     # end
#
#   end
# end
#
# #ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: 'db/test.sqlite3'
#
# #ActiveRecord::Schema.define do
#   # unless ActiveRecord::Base.connection.tables.include? 'synchromesh_connections'
#   #   ActiveRecord::Base.connection_pool.with_connection do |conn|
#   #     conn.create_table(:synchromesh_connections, force: :cascade) do |t|
#   #       t.string :channel
#   #       t.string :session
#   #       t.datetime :updated_at
#   #       t.datetime :expires_at
#   #       t.datetime :refresh_at
#   #     end
#   #     conn.close
#   #   end
#   # end
#
# # unless Synchromesh::Connection.connection.tables.include? 'synchromesh_connections'
# #   Synchromesh::Connection.connection.create_table(:synchromesh_connections) do |t|
# #     t.string :channel
# #     t.string :session
# #     t.datetime :updated_at
# #     t.datetime :expires_at
# #     t.datetime :refresh_at
# #   end
# # end
