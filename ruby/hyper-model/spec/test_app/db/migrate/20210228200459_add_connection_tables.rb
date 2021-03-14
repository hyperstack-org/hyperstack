class AddConnectionTables < ActiveRecord::Migration[5.2]
  def change
    create_table "hyperstack_connections", force: :cascade do |t|
      t.string "channel"
      t.string "session"
      t.datetime "created_at"
      t.datetime "expires_at"
      t.datetime "refresh_at"
    end

    create_table "hyperstack_queued_messages", force: :cascade do |t|
      t.text "data"
      t.integer "connection_id"
    end
  end
end
