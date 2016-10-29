class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.integer  :user_id
      t.integer  :todo_item_id
      t.string   :comment
      t.timestamps
    end
  end
end
