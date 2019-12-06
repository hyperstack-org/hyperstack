# frozen_string_literal: true

require_relative 'redis_record'

module Hyperstack
  module ConnectionAdapter
    module Redis
      class Connection < RedisRecord::Base
        self.table_name = 'hyperstack:connections'
        self.column_names = %w[id channel session created_at expires_at refresh_at].freeze

        attr_accessor(*column_names.map(&:to_sym))

        class << self
          def transport
            Hyperstack::Connection.transport
          end

          def create(opts = {})
            opts.tap do |hash|
              if opts[:session]
                hash[:expires_at] = (Time.current + transport.expire_new_connection_in)
              elsif transport.refresh_channels_every != :never
                hash[:refresh_at] = (Time.current + transport.refresh_channels_every)
              end

              hash[:created_at] = Time.current
            end.to_a.flatten

            super(opts)
          end

          def inactive
            scope { |id| id if inactive?(id) }
          end

          def inactive?(id)
            get_dejsonized_attribute(id, :session).blank? &&
              get_dejsonized_attribute(id, :refresh_at).present? &&
              Time.zone.parse(get_dejsonized_attribute(id, :refresh_at)) < Time.current
          end

          def expired
            scope { |id| id if expired?(id) }
          end

          def expired?(id)
            get_dejsonized_attribute(id, :expires_at).present? &&
              Time.zone.parse(get_dejsonized_attribute(id, :expires_at)) < Time.current
          end

          def pending_for(channel)
            scope { |id| id if pending_for?(id, channel) }
          end

          def pending_for?(id, channel)
            get_dejsonized_attribute(id, :session).present? &&
              get_dejsonized_attribute(id, :channel) == channel
          end

          def needs_refresh?
            scope { |id| id if needs_refresh(id) }.any?
          end

          def needs_refresh(id)
            get_dejsonized_attribute(id, :refresh_at).present? &&
              Time.zone.parse(get_dejsonized_attribute(id, :refresh_at)) < Time.current
          end
        end

        def messages
          QueuedMessage.where(connection_id: id)
        end

        %i[created_at expires_at refresh_at].each do |attr|
          define_method(attr) do
            value = instance_variable_get(:"@#{attr}")

            value.is_a?(Time) ? value : Time.zone.parse(value)
          end
        end
      end
    end
  end
end
