# frozen_string_literal: true

require_relative 'redis_record'

module Hyperstack
  module ConnectionAdapter
    module Redis
      class QueuedMessage < RedisRecord::Base
        self.table_name = 'hyperstack:queued_messages'
        self.column_names = %w[id data connection_id].freeze

        attr_accessor(*column_names.map(&:to_sym))

        class << self
          def for_session(session)
            Connection.where(session: session).map(&:messages).flatten
          end

          def root_path=(path)
            find_or_create_by(connection_id: 0).update(data: path)
          end

          def root_path
            find_or_create_by(connection_id: 0).data
          end
        end

        def connection
          Connection.find(connection_id)
        end
      end
    end
  end
end
