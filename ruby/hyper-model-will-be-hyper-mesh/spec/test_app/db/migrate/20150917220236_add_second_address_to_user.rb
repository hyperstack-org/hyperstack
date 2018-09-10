class AddSecondAddressToUser < ActiveRecord::Migration
  def change

    add_column :users, :address2_street, :string
    add_column :users, :address2_city,   :string
    add_column :users, :address2_state,  :string
    add_column :users, :address2_zip,    :string

  end
end
