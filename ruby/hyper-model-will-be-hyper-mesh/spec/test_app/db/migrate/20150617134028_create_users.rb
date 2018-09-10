class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :email

      t.timestamps
    end
    
    add_column :todo_items, :user_id, :integer
    
  end
end
