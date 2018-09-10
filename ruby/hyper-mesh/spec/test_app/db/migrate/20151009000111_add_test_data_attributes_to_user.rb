class AddTestDataAttributesToUser < ActiveRecord::Migration
  def change
    add_column :users, :data_string, :string
    add_column :users, :data_times, :integer
  end
end
