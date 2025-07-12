class CreateDrops < ActiveRecord::Migration[7.2]
  def change
    create_table :drops do |t|
      t.references :team, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true

      t.string :img_url
      t.string :owner
      t.string :reviewed_by
      t.string :status

      t.timestamps
    end
  end
end
