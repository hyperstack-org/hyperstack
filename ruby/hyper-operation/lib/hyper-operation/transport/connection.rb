# frozen_string_literal: true

module Hyperstack
  class Connection
    class << self
      attr_accessor :transport, :connection_adapter, :show_diagnostics

      def adapter
        adapter_name = Hyperstack.connection[:adapter].to_s
        adapter_path = "hyper-operation/transport/connection_adapter/#{adapter_name}"

        begin
          require adapter_path
        rescue LoadError => e
          if e.path == adapter_path
            raise e.class, "Could not load the '#{adapter_name}' adapter. Make sure the adapter is spelled correctly in your Hyperstack config, and the necessary gems are in your Gemfile.", e.backtrace

          # Bubbled up from the adapter require. Prefix the exception message
          # with some guidance about how to address it and reraise.
          else
            raise e.class, "Error loading the '#{adapter_name}' adapter. Missing a gem it depends on? #{e.message}", e.backtrace
          end
        end

        adapter_name = adapter_name.camelize
        "Hyperstack::ConnectionAdapter::#{adapter_name}".constantize
      end

      def build_tables
        adapter.build_tables
      end

      def build_tables?
        adapter.respond_to?(:build_tables)
      end

      def active
        adapter.active
      end

      def open(channel, session = nil, root_path = nil)
        puts "open(#{channel}, #{session}, #{root_path})" if show_diagnostics

        adapter.open(channel, session, root_path).tap do |c|
          puts " - open returning #{c}" if show_diagnostics
        end
      end

      def send_to_channel(channel, data)
        adapter.send_to_channel(channel, data)
      end

      def read(session, root_path)
        adapter.read(session, root_path)
      end

      def connect_to_transport(channel, session, root_path)
        puts "connect_to_transport(#{channel}, #{session}, #{root_path})" if show_diagnostics

        adapter.connect_to_transport(channel, session, root_path)
      end

      def disconnect(channel)
        adapter.disconnect(channel)
      end

      def root_path=(path)
        adapter.root_path = path
      end

      def root_path
        adapter.root_path
      end

      def refresh_connections
        adapter.refresh_connections
      end

      def method_missing(method_name, *args, &block)
        if adapter::Connection.respond_to?(method_name)
          adapter::Connection.send(method_name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        adapter::Connection.respond_to?(method_name)
      end
    end
  end
end
