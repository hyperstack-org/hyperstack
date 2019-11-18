class CreateTestModels < ActiveRecord::Migration[5.2]
  def change
    create_table :test_models do |t|
      t.string :test_attribute
      t.boolean :completed
      t.timestamps null: false
    end

    create_table :child_models do |t|
      t.string :child_attribute
      t.belongs_to :test_model
    end

    create_table :users do |t|
      t.string :role
      t.references :manager
      t.string   "first_name"
      t.string   "last_name"
      t.string   "email"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "address_street"
      t.string   "address_city"
      t.string   "address_state"
      t.string   "address_zip"
      t.integer  "address_id"
      t.string   "address2_street"
      t.string   "address2_city"
      t.string   "address2_state"
      t.string   "address2_zip"
      t.string   "data_string"
      t.integer  "data_times"
      t.integer  "test_enum"
    end

    create_table :todos do |t|
      t.string :title
      t.text :description
      t.timestamps null: false
      t.boolean :completed, default: false, null: false
      t.references :created_by
      t.references :owner
    end

    create_table :comments do |t|
      t.text :comment
      t.timestamps null: false
      t.belongs_to :todo
      t.references :author
      t.integer  "user_id"
      t.integer  "todo_item_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "addresses" do |t|
      t.string   "street"
      t.string   "city"
      t.string   "state"
      t.string   "zip"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "todo_items" do |t|
      t.string   "title"
      t.text     "description"
      t.boolean  "complete"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "user_id"
      t.integer  "comment_id"
    end

    create_table :pets do |t|
      t.integer :owner_id
    end

    create_table :bones do |t|
      t.integer :dog_id
    end

    create_table :scratching_posts do |t|
      t.integer :cat_id
    end
  end
end
