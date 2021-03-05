class RemoveNullFromUserColumns < ActiveRecord::Migration[6.1]
  def change
    change_column :users, :image_url, :string, null: true
  end
end
