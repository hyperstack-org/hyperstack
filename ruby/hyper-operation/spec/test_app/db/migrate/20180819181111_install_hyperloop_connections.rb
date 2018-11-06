class InstallHyperstackConnections < ActiveRecord::Migration[5.2]
  def change

    create_table :hyperstack_connections do |t|
      t.string :channel
      t.string :session
      t.datetime :created_at
      t.datetime :expires_at, index: true
      t.datetime :refresh_at
    end

    create_table :hyperstack_queued_messages do |t|
      t.integer :connection_id, index: true
      t.text :data
    end

  end
end
