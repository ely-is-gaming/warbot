class AddConditionalModifierToTiles < ActiveRecord::Migration[7.2]
  def change
    add_column :tiles, :conditional_modifier, :integer, default: 0, null: false
  end
end
