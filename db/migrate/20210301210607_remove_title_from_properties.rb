class RemoveTitleFromProperties < ActiveRecord::Migration[6.1]
  def change
    remove_column :properties, :title
  end
end
