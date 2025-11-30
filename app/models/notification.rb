class Notification < ApplicationRecord
  belongs_to :message

  validates :reason, presence: true, inclusion: { in: %w[dm highlight] }

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc).limit(50) }

  def read?
    read_at.present?
  end

  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end
end
