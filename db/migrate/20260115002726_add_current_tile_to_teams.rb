class AddCurrentTileToTeams < ActiveRecord::Migration[7.2]
  def change
    add_column :teams, :current_tile, :integer, default: 1
  end
end
