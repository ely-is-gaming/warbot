class AddImagePathToTiles < ActiveRecord::Migration[7.2]
  def change
    add_column :tiles, :image_path, :string
  end
end
