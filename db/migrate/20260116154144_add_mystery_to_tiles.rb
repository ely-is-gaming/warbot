class AddMysteryToTiles < ActiveRecord::Migration[7.2]
  def change
    add_column :tiles, :mystery, :boolean, default: false
  end
end
