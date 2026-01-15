class AddModifierToTiles < ActiveRecord::Migration[7.2]
  def change
    add_column :tiles, :modifier, :integer, default: 0, null: false
  end
end
