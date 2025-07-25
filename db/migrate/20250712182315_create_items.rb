class CreateItems < ActiveRecord::Migration[7.2]
  def change
    create_table :items do |t|
      t.string :name
      t.string :category
      t.integer :points
      t.references :completed_set, null: false, foreign_key: true

      t.timestamps
    end
  end
end
