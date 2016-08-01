class CreateTestModels < ActiveRecord::Migration
  def change
    create_table :test_models do |t|
      t.string :test_attribute
      t.boolean :completed
      t.timestamps null: false
    end
  end
end
