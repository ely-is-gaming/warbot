class PendingDropReview < ApplicationRecord
  STATUSES = %w[pending approved denied].freeze

  validates :review_message_id, presence: true, uniqueness: true
  validates :review_channel_id, :team_name, :drop_name, :image_url, :submitter, :status, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }

  def pending?
    status == "pending"
  end
end
