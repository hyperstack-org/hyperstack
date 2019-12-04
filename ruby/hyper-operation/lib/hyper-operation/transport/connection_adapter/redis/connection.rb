# frozen_string_literal: true

require_relative 'redis_record'

module Hyperstack
  module ConnectionAdapter
    module Redis
      class Connection < RedisRecord::Base
        self.table_name = 'hyperstack:connections'
        self.column_names = %w[id channel session created_at expires_at refresh_at].freeze

        attr_accessor(*column_names.map(&:to_sym))

        def messages
          QueuedMessage.where(connection_id: id)
        end

        class << self
          def transport
            Hyperstack::Connection.transport
          end

          def create(opts = {})
            opts.tap do |hash|
              if opts[:session]
                hash[:expires_at] = (Time.current + transport.expire_new_connection_in)
              else
                hash[:refresh_at] = (Time.current + transport.refresh_channels_every)
              end

              hash[:created_at] = Time.current
            end.to_a.flatten

            super(opts)
          end

          def inactive
            scope { |id| new(client.hgetall("#{table_name}:#{id}")) if inactive?(id) }
          end

          def inactive?(id)
            client.hget("#{table_name}:#{id}", :session).blank? &&
              client.hget("#{table_name}:#{id}", :refresh_at).present? &&
              Time.zone.parse(client.hget("#{table_name}:#{id}", :refresh_at)) < Time.current
          end

          def expired
            scope { |id| new(client.hgetall("#{table_name}:#{id}")) if expired?(id) }
          end

          def expired?(id)
            client.hget("#{table_name}:#{id}", :expires_at).present? &&
              Time.zone.parse(client.hget("#{table_name}:#{id}", :expires_at)) < Time.current
          end

          def pending_for(channel)
            scope { |id| new(client.hgetall("#{table_name}:#{id}")) if pending_for?(id, channel) }
          end

          def pending_for?(id, channel)
            client.hget("#{table_name}:#{id}", :session).present? &&
              client.hget("#{table_name}:#{id}", :channel) == channel
          end

          def needs_refresh?
            scope { |id| new(client.hgetall("#{table_name}:#{id}")) if needs_refresh(id) }.any?
          end

          def needs_refresh(id)
            client.hget("#{table_name}:#{id}", :refresh_at).present? &&
              Time.zone.parse(client.hget("#{table_name}:#{id}", :refresh_at)) < Time.current
          end
        end
      end
    end
  end
end
