class CreateAddresses < ActiveRecord::Migration[6.1]
  def change
    create_table :addresses do |t|
      t.string :line_1, null: false
      t.string :line_2, null: true
      t.string :city, null: false
      t.string :state, null: false
      t.integer :zip, null: false

      t.timestamps
    end
  end
end
