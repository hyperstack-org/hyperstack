# frozen_string_literal: true

require_relative 'active_record/connection'
require_relative 'active_record/queued_message'

module Hyperstack
  module ConnectionAdapter
    module ActiveRecord
      class << self
        def build_tables
          Connection.create_table(force: :cascade) do |t|
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

        def transport
          Hyperstack::Connection.transport
        end

        def active
          # if table doesn't exist then we are either calling from within
          # a migration or from a console before the server has ever started
          # in these cases there are no channels so we return nothing
          return [] unless Connection.table_exists?

          if Hyperstack.on_server?
            Connection.expired.delete_all
            refresh_connections if Connection.needs_refresh?
          end

          Connection.all.pluck(:channel).uniq
        end

        def open(channel, session = nil, root_path = nil)
          self.root_path = root_path

          Connection.find_or_create_by(channel: channel, session: session)
        end

        def send_to_channel(channel, data)
          Connection.pending_for(channel).each do |connection|
            QueuedMessage.create(data: data, hyperstack_connection: connection)
          end

          transport.send_data(channel, data) if Connection.exists?(channel: channel, session: nil)
        end

        def read(session, root_path)
          self.root_path = root_path

          Connection.where(session: session)
                    .update_all(expires_at: Time.current + transport.expire_polled_connection_in)

          QueuedMessage.for_session(session).destroy_all.pluck(:data)
        end

        def connect_to_transport(channel, session, root_path)
          self.root_path = root_path

          if (connection = Connection.find_by(channel: channel, session: session))
            messages = connection.messages.pluck(:data)
            connection.destroy
          else
            messages = []
          end

          open(channel)

          messages
        end

        def disconnect(channel)
          Connection.find_by(channel: channel, session: nil).destroy
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
          refresh_started_at = Time.current
          channels = transport.refresh_channels
          next_refresh = refresh_started_at + transport.refresh_channels_every

          channels.each do |channel|
            connection = Connection.find_by(channel: channel, session: nil)
            connection.update(refresh_at: next_refresh) if connection
          end

          Connection.inactive.delete_all
        end
      end
    end
  end
end
