# frozen_string_literal: true

module Hyperstack
  module ConnectionAdapter
    module Redis
      module RedisRecord
        class Base
          class << self
            attr_accessor :table_name

            def connection_pool
              @connection_pool ||= ConnectionPool.new(size: Hyperstack.connection[:pool]) do
                ::Redis.new(url: Hyperstack.connection[:redis_url])
              end
            end

            def client
              connection_pool.with { |c| return c }
            end

            def attributes(attrs = nil)
              if attrs
                @attributes = attrs
              else
                @attributes
              end
            end

            def scope(&block)
              ids = client.smembers(table_name)

              ids = ids.map(&block) if block

              ids.compact.map { |id| instantiate(id) }
            end

            def all
              scope
            end

            def first
              id = client.smembers(table_name).first

              instantiate(id)
            end

            def last
              id = client.smembers(table_name).last

              instantiate(id)
            end

            def find(id)
              return unless client.smembers(table_name).include?(id)

              instantiate(id)
            end

            def find_by(opts)
              found = nil

              client.smembers(table_name).each do |id|
                unless opts.map { |k, v| get_dejsonized_attribute(id, k) == v }.include?(false)
                  found = instantiate(id)
                  break
                end
              end

              found
            end

            def find_or_create_by(opts = {})
              if (existing = find_by(opts))
                existing
              else
                create(opts)
              end
            end

            def where(opts = {})
              scope do |id|
                unless opts.map { |k, v| get_dejsonized_attribute(id, k) == v }.include?(false)
                  id
                end
              end
            end

            def exists?(opts = {})
              !!client.smembers(table_name).detect do |id|
                !opts.map { |k, v| get_dejsonized_attribute(id, k) == v }.include?(false)
              end
            end

            def create(opts = {})
              record = new({ id: SecureRandom.uuid }.merge(opts))

              record.save

              record
            end

            def destroy_all
              all.each(&:destroy)

              true
            end

            protected

            def instantiate(id)
              new(client.hgetall("#{table_name}:#{id}"))
            end
          end

          attr_reader :attributes

          def key
            "#{table_name}:#{attributes['id']}"
          end

          def initialize(opts = {})
            @attributes = {}

            opts.each { |k, v| attributes[k.to_s] = v }
          end

          def save
            client.hmset(key, *attributes)
            client.sadd(table_name, attributes['id'])

            update_indexes

            true
          end

          def update_indexes
            self.class.attributes.each do |column_name, _klass|
              value = attributes[column_name.to_s]
              value ||= -1 # We use -1 so we can filter out nil entries

              client.zadd("#{table_name}_#{column_name}", value.to_i, key)
            end
          end

          def remove_indexes
            self.class.attributes.each do |column_name, _klass|
              client.zrem("#{table_name}_#{column_name}", key)
            end
          end

          def update(opts = {})
            opts.each { |k, v| attributes[k.to_s] = v }

            save
          end

          def destroy
            remove_indexes
            client.srem(table_name, attributes["id"])

            client.hdel(key, attributes.keys)

            true
          end

          def table_name
            self.class.table_name
          end

          protected

          def client
            self.class.connection_pool.with { |c| return c }
          end
        end
      end
    end
  end
end
