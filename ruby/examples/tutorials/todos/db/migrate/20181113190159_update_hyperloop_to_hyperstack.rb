    class DropHyperloopTables < ActiveRecord::Migration[5.2]
      def change
        drop_table :hyperstack_connections
        drop_table :hyperloop_connections
        drop_table :hyperstack_queued_messages
        drop_table :hyperloop_queued_messages
      end
    end
