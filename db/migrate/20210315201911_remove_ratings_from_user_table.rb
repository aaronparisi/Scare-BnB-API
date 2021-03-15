class RemoveRatingsFromUserTable < ActiveRecord::Migration[6.1]
  def change
    remove_column :users, :guest_rating
    remove_column :users, :host_rating
  end
end
