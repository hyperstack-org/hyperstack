# frozen_string_literal: true

require_relative 'auto_create'

module Hyperstack
  module ConnectionAdapter
    module ActiveRecord
      class Connection < ::ActiveRecord::Base
        extend AutoCreate

        self.table_name = 'hyperstack_connections'

        do_not_synchronize

        has_many :messages,
                foreign_key: 'connection_id',
                class_name: 'Hyperstack::ConnectionAdapter::ActiveRecord::QueuedMessage',
                dependent: :destroy

        scope :expired,
              -> { where('expires_at IS NOT NULL AND expires_at < ?', Time.zone.now) }
        scope :pending_for,
              ->(channel) { where(channel: channel).where('session IS NOT NULL') }
        scope :inactive,
              -> { where('session IS NULL AND refresh_at < ?', Time.zone.now) }

        before_create do
          if session
            self.expires_at = Time.now + transport.expire_new_connection_in
          elsif transport.refresh_channels_every != :never
            self.refresh_at = Time.now + transport.refresh_channels_every
          end
        end

        class << self
          def needs_refresh?
            exists?(['refresh_at IS NOT NULL AND refresh_at < ?', Time.zone.now])
          end
        end

        def transport
          Hyperstack::Connection.transport
        end
      end
    end
  end
end
