class AddPropertyIdToAddresses < ActiveRecord::Migration[6.1]
  def change
    add_reference :addresses, :property, foreign_key: true
    remove_column :properties, :address_id
  end
end
