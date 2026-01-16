class CreateMysteryTiles < ActiveRecord::Migration[7.2]
  def change
    create_table :mystery_tiles do |t|
      t.string :name
      t.string :image_path
      t.integer :modifier

      t.timestamps
    end
  end
end
