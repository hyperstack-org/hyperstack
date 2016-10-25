class AddTestEnumToUser < ActiveRecord::Migration
  def change
    add_column :users, :test_enum, :integer
  end
end
