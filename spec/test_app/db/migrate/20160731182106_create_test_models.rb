class CreateTestModels < ActiveRecord::Migration
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
      t.string :name
      t.references :manager
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
    end
  end
end
