class CompletedSetIdNullableOnItems < ActiveRecord::Migration[7.2]
  def change
    change_column_null :items, :completed_set_id, true
  end
end
