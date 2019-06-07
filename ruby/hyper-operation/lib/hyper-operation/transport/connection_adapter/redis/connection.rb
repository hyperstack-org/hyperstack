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
            id = SecureRandom.uuid

            opts.tap do |hash|
              hash[:id] = id

              if opts[:session]
                hash[:expires_at] = Time.now + transport.expire_new_connection_in
              else
                hash[:refresh_at] = Time.now + transport.refresh_channels_every
              end

              hash[:created_at] = Time.now
            end.to_a.flatten

            client.hmset("#{table_name}:#{id}", *opts)
            client.sadd(table_name, id)

            new(client.hgetall("#{table_name}:#{id}"))
          end

          def inactive
            scope { |id| new(client.hgetall("#{table_name}:#{id}")) if inactive?(id) }
          end

          def inactive?(id)
            client.hget("#{table_name}:#{id}", :session).blank? &&
              client.hexists("h#{table_name}:#{id}", :refresh_at) &&
              Time.parse(client.hget("#{table_name}:#{id}", :refresh_at)) < Time.zone.now
          end

          def expired
            scope { |id| new(client.hgetall("#{table_name}:#{id}")) if expired?(id) }
          end

          def expired?(id)
            client.hexists("#{table_name}:#{id}", :expires_at) &&
              Time.parse(client.hget("#{table_name}:#{id}", :expires_at)) < Time.zone.now
          end

          def pending_for(channel)
            scope { |id| new(client.hgetall("#{table_name}:#{id}")) if pending_for?(id, channel) }
          end

          def pending_for?(id, channel)
            !client.hget("#{table_name}:#{id}", :session).blank? &&
              client.hget("#{table_name}:#{id}", :channel) == channel
          end

          def needs_refresh?
            scope { |id| new(client.hgetall("#{table_name}:#{id}")) if needs_refresh(id) }
          end

          def needs_refresh(id)
            client.hexists("#{table_name}:#{id}", :refresh_at) &&
              Time.parse(client.hget("#{table_name}:#{id}", :refresh_at)) < Time.zone.now
          end
        end
      end
    end
  end
end