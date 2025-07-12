class CreateCompletedSets < ActiveRecord::Migration[7.2]
  def change
    create_table :completed_sets do |t|
      t.string :name
      t.references :team, null: false, foreign_key: true

      t.timestamps
    end
  end
end
