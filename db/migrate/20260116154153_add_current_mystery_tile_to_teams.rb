class AddCurrentMysteryTileToTeams < ActiveRecord::Migration[7.2]
  def change
    add_reference :teams, :current_mystery, foreign_key: { to_table: :mystery_tiles }
  end
end
