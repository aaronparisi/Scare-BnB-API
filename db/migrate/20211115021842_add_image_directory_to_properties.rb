class AddImageDirectoryToProperties < ActiveRecord::Migration[6.1]
  def change
    add_column :properties, :image_directory, :string
  end
end
