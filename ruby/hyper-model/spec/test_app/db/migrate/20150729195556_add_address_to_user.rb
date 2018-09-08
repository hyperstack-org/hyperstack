class AddAddressToUser < ActiveRecord::Migration
  
  def change
    
    add_column :users, :address_street, :string
    add_column :users, :address_city,   :string
    add_column :users, :address_state,  :string
    add_column :users, :address_zip,    :string
    
    create_table :addresses do |t|
      t.string :street
      t.string :city
      t.string :state
      t.string :zip
      t.timestamps
    end
    
  end
  
end
