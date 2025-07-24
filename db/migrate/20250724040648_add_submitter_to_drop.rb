class AddSubmitterToDrop < ActiveRecord::Migration[7.2]
  def change
    add_column :drops, :submitter, :string
  end
end
