class CreateBookings < ActiveRecord::Migration[6.1]
  def change
    create_table :bookings do |t|
      t.references :property, null: false, foreign_key: true
      t.references :guest, null: false, index: true, foreign_key: { to_table: :users }
      t.date :start_date, null: false
      t.date :end_date, null: false

      t.timestamps
    end
  end
end
