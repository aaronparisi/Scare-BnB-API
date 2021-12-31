class RemoveImageDirectoryFromProperties < ActiveRecord::Migration[6.1]
  def change
    remove_column :properties, :image_directory
  end
end
