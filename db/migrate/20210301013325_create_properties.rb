class CreateProperties < ActiveRecord::Migration[6.1]
  def change
    create_table :properties do |t|
      t.references :address, null: false, foreign_key: true
      t.integer :beds, null: false
      t.integer :baths, null: false
      t.integer :square_feet, null: false
      t.boolean :smoking, null: false
      t.boolean :pets, null: false
      t.decimal :nightly_rate, null: false, inclusion: { minimum: 0 }, precision: 10, scale: 2
      t.text :description, null: false
      t.references :manager, null: false, index: true, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
