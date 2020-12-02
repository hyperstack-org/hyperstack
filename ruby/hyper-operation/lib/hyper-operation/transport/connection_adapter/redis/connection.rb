# frozen_string_literal: true

require_relative 'redis_record'

module Hyperstack
  module ConnectionAdapter
    module Redis
      class Connection < RedisRecord::Base
        self.table_name = 'hyperstack:connections'

        attributes id:         String,
                   channel:    String,
                   session:    String,
                   created_at: Integer,
                   expires_at: Integer,
                   refresh_at: Integer

        class << self
          def transport
            Hyperstack::Connection.transport
          end

          def create(opts = {})
            opts.tap do |hash|
              if opts["session"]
                hash["expires_at"] = (Time.now + transport.expire_new_connection_in).to_i
              elsif transport.refresh_channels_every != :never
                hash["refresh_at"] = (Time.now + transport.refresh_channels_every).to_i
              end

              hash["created_at"] = Time.now.to_i
            end.to_a.flatten

            super(opts)
          end

          def inactive
            client.zrangebyscore("#{table_name}_session", -1, -1) &
              client.zrangebyscore("#{table_name}_refresh_at", 0, Time.now.to_i)
          end

          def expired
            client.zrangebyscore("#{table_name}_expires_at", 0, Time.now.to_i)
          end

          def pending_for(channel)
            (client.zrangebyscore("#{table_name}_session", 0, 0) &
              client.smembers("#{table_name}_channel"))
              .select { |id| client.hget(id, "channel") == channel }
          end

          def needs_refresh?
            client.zrangebyscore("#{table_name}_refresh_at", 0, Time.now.to_i).any?
          end
        end

        def messages
          QueuedMessage.where(connection_id: id)
        end
      end
    end
  end
end
