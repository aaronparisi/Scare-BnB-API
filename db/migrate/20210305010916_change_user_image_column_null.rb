class ChangeUserImageColumnNull < ActiveRecord::Migration[6.1]
  def change
    change_column_null :users, :image_url, true
  end
end
