# frozen_string_literal: true

module Hyperstack
  module ConnectionAdapter
    module Redis
      module RedisRecord
        class Base
          class << self
            attr_accessor :table_name, :column_names

            def client
              @client ||= ::Redis.new(url: Hyperstack.connection[:redis_url])
            end

            def scope(&block)
              client.smembers(table_name).map(&block).compact
            end

            def all
              scope { |id| new(client.hgetall("#{table_name}:#{id}")) }
            end

            def first
              id = client.smembers(table_name).first

              new(client.hgetall("#{table_name}:#{id}"))
            end

            def last
              id = client.smembers(table_name).last

              new(client.hgetall("#{table_name}:#{id}"))
            end

            def find(id)
              return unless client.smembers(table_name).include?(id)

              new(client.hgetall("#{table_name}:#{id}"))
            end

            def find_by(opts)
              found = nil

              client.smembers(table_name).each do |id|
                unless opts.map { |k, v| client.hget("#{table_name}:#{id}", k) == v.to_s }.include?(false)
                  found = new(client.hgetall("#{table_name}:#{id}"))
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
                unless opts.map { |k, v| client.hget("#{table_name}:#{id}", k) == v.to_s }.include?(false)
                  new(client.hgetall("#{table_name}:#{id}"))
                end
              end
            end

            def exists?(opts = {})
              !!client.smembers(table_name).detect do |uuid|
                !opts.map { |k, v| client.hget("#{table_name}:#{uuid}", k) == v.to_s }.include?(false)
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
          end

          def initialize(opts = {})
            opts.each { |k, v| send(:"#{k}=", v) }
          end

          def save
            self.class.client.hmset("#{table_name}:#{id}", *attributes)

            unless self.class.client.smembers(table_name).include?(id)
              self.class.client.sadd(table_name, id)
            end

            true
          end

          def update(opts = {})
            opts.each { |k, v| send(:"#{k}=", v) }
            save
          end

          def destroy
            self.class.client.srem(table_name, id)

            self.class.client.hdel("#{table_name}:#{id}", attributes.keys)

            true
          end

          def attributes
            self.class.column_names.map do |column_name|
              [column_name, instance_variable_get("@#{column_name}")]
            end.to_h
          end

          def table_name
            self.class.table_name
          end
        end
      end
    end
  end
end
