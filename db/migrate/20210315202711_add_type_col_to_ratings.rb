class AddTypeColToRatings < ActiveRecord::Migration[6.1]
  def change
    add_column :ratings, :type, :string, inclusion: ["guest", "manager"]
  end
end
