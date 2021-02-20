# frozen_string_literal: true

require_relative 'auto_create'

module Hyperstack
  module ConnectionAdapter
    module ActiveRecord
      class QueuedMessage < ::ActiveRecord::Base
        extend AutoCreate

        self.table_name = 'hyperstack_queued_messages'

        do_not_synchronize

        serialize :data

        belongs_to :hyperstack_connection,
                   class_name:  'Hyperstack::ConnectionAdapter::ActiveRecord::Connection',
                   foreign_key: 'connection_id',
                   optional:    true

        scope :for_session,
              ->(session) { joins(:hyperstack_connection).where('session = ?', session) }

        # For simplicity we use QueuedMessage with connection_id 0
        # to store the current path which is used by consoles to
        # communicate back to the server. The belongs_to connection
        # therefore must be optional.

        default_scope { where('connection_id IS NULL OR connection_id != 0') }

        def self.root_path=(path)
          unscoped.find_or_create_by(connection_id: 0).update(data: path)
        end

        def self.root_path
          unscoped.find_or_create_by(connection_id: 0).data
        end
      end
    end
  end
end
