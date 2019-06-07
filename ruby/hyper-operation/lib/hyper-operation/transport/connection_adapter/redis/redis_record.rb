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

              client.hget("#{table_name}:#{id}")
            end

            def find_by(opts)
              found = nil

              client.smembers(table_name).each do |id|
                unless opts.map { |k, v| client.hget("#{table_name}:#{id}", k) == v }.include?(false)
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
                unless opts.map { |k, v| client.hget("#{table_name}:#{id}", k) == v }.include?(false)
                  new(client.hgetall("#{table_name}:#{id}"))
                end
              end
            end

            def exists?(opts = {})
              !!client.smembers(table_name).detect do |uuid|
                !opts.map { |k, v| client.hget("#{table_name}:#{uuid}", k) == v }.include?(false)
              end
            end

            def destroy_all
              all.each(&:destroy)
            end
          end

          def initialize(opts = {})
            opts.each { |k, v| send(:"#{k}=", v) }
          end

          def save
            self.class.client.hmset("#{table_name}:#{id}", *attributes)
          end

          def update(opts = {})
            opts.each { |k, v| send(:"#{k}=", v) }
            save
          end

          def destroy
            self.class.client.srem(table_name, id)

            self.class.client.hdel("#{table_name}:#{id}", attributes.keys)
          end

          def attributes
            self.class.client.hgetall("#{table_name}:#{id}")
          end

          def table_name
            self.class.table_name
          end
        end
      end
    end
  end
end
