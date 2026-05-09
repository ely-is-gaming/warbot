class CreatePendingDropReviews < ActiveRecord::Migration[7.2]
  def change
    create_table :pending_drop_reviews do |t|
      t.string :review_message_id, null: false
      t.string :review_channel_id, null: false
      t.string :team_name, null: false
      t.string :drop_name, null: false
      t.string :image_url, null: false
      t.string :owner
      t.string :submitter, null: false
      t.string :submitter_user_id
      t.string :status, null: false, default: "pending"
      t.string :reviewed_by
      t.string :reviewed_by_user_id
      t.datetime :reviewed_at

      t.timestamps
    end

    add_index :pending_drop_reviews, :review_message_id, unique: true
    add_index :pending_drop_reviews, :status
  end
end
