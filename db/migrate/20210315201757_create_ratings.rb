class CreateRatings < ActiveRecord::Migration[6.1]
  def change
    create_table :ratings do |t|
      t.references :manager, null: false, index: true, foreign_key: { to_table: :users }
      t.references :guest, null: false, index: true, foreign_key: { to_table: :users }
      t.integer :rating, null: false, inclusion: 0..5

      t.timestamps
    end
  end
end
