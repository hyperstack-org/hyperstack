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
  end
end
