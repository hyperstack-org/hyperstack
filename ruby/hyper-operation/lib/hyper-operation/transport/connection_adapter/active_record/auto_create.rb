# frozen_string_literal: true

module Hyperstack
  module ConnectionAdapter
    module ActiveRecord
      module AutoCreate
        def table_exists?
          # works with both rails 4 and 5 without deprecation warnings
          if connection.respond_to?(:data_sources)
            connection.data_sources.include?(table_name)
          else
            connection.tables.include?(table_name)
          end
        end

        def needs_init?
          Hyperstack.transport != :none && Hyperstack.on_server? && !table_exists?
        end

        def create_table(*args, &block)
          connection.create_table(table_name, *args, &block) if needs_init?
        end
      end
    end
  end
end
