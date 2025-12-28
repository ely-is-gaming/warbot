class CreateDiceRoll < ActiveRecord::Migration[7.2]
  def change
    create_table :dice_rolls do |t|
      t.references :team, null: false, foreign_key: true
      t.integer :roll

      t.timestamps
    end
  end
end
