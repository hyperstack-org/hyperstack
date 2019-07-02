module Hyperstack
  module AutoCreate
    def table_exists?
      # works with both rails 4 and 5 without deprecation warnings
      if connection.respond_to?(:data_sources)
        connection.data_sources.include?(table_name)
      else
        connection.tables.include?(table_name)
      end
    end

    def needs_init?
      Hyperstack.transport != :none && Hyperstack.on_server? && !table_exists?
    end

    def create_table(*args, &block)
      connection.create_table(table_name, *args, &block) if needs_init?
    end
  end

  class Connection < ActiveRecord::Base
    class QueuedMessage < ActiveRecord::Base

      extend AutoCreate

      self.table_name = 'hyperstack_queued_messages'

      do_not_synchronize

      serialize :data

      belongs_to :hyperstack_connection,
                 class_name: 'Hyperstack::Connection',
                 foreign_key: 'connection_id'

      scope :for_session,
            ->(session) { joins(:hyperstack_connection).where('session = ?', session) }

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

    extend AutoCreate

    def self.build_tables
      create_table(force: :cascade) do |t|
        t.string   :channel
        t.string   :session
        t.datetime :created_at
        t.datetime :expires_at
        t.datetime :refresh_at
      end
      QueuedMessage.create_table(force: :cascade) do |t|
        t.text    :data
        t.integer :connection_id
      end
    end

    do_not_synchronize

    self.table_name = 'hyperstack_connections'

    has_many :messages,
             foreign_key: 'connection_id',
             class_name: 'Hyperstack::Connection::QueuedMessage',
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
      attr_accessor :show_diagnostics

      def active
        # if table doesn't exist then we are either calling from within
        # a migration or from a console before the server has ever started
        # in these cases there are no channels so we return nothing
        return [] unless table_exists?
        if Hyperstack.on_server?
          expired.delete_all
          refresh_connections if needs_refresh?
        end
        all.pluck(:channel).uniq
      end

      def open(channel, session = nil, root_path = nil)
        puts "open(#{channel}, #{session}, #{root_path})" if show_diagnostics
        self.root_path = root_path
        find_or_create_by(channel: channel, session: session).tap { |c| puts " - open returning #{c}" if show_diagnostics}
      end

      def send_to_channel(channel, data)
        pending_for(channel).each do |connection|
          QueuedMessage.create(data: data, hyperstack_connection: connection)
        end
        transport.send_data(channel, data) if exists?(channel: channel, session: nil)
      end

      def read(session, root_path)
        self.root_path = root_path
        where(session: session)
          .update_all(expires_at: Time.now + transport.expire_polled_connection_in)
        QueuedMessage.for_session(session).destroy_all.pluck(:data)
      end

      def connect_to_transport(channel, session, root_path)
        puts "connect_to_transport(#{channel}, #{session}, #{root_path})" if show_diagnostics
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
        # if the QueuedMessage table doesn't exist then we are either calling from within
        # a migration or from a console before the server has ever started
        # in these cases there is no root path to the server
        QueuedMessage.root_path if QueuedMessage.table_exists?
      end

      def refresh_connections
        refresh_started_at = Time.zone.now
        channels = transport.refresh_channels
        next_refresh = refresh_started_at + transport.refresh_channels_every
        channels.each do |channel|
          connection = find_by(channel: channel, session: nil)
          connection.update(refresh_at: next_refresh) if connection
        end
        inactive.delete_all
      end
    end
  end
end
