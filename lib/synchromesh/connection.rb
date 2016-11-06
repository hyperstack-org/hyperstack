module HyperMesh
  class Connection < ActiveRecord::Base
    class QueuedMessage < ActiveRecord::Base
      self.table_name = 'synchromesh_queued_messages'

      do_not_synchronize

      serialize :data

      belongs_to :synchromesh_connection,
                 class_name: 'HyperMesh::Connection',
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
             class_name: 'HyperMesh::Connection::QueuedMessage',
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
      rescue Exception => e
        binding.pry
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

# Add pluck to enumerable... its already done for us in rails 5+
module Enumerable
  def pluck(key)
    map { |element| element[key] }
  end
end unless Enumerable.method_defined? :pluck
