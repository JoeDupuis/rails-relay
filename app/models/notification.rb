class Notification < ApplicationRecord
  belongs_to :message

  validates :reason, presence: true, inclusion: { in: %w[dm highlight] }

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc).limit(50) }
  scope :for_user, ->(user) { joins(message: :server).where(servers: { user_id: user.id }) }

  def self.mark_all_as_read!
    unread.update_all(read_at: Time.current)
  end

  def read?
    read_at.present?
  end

  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end
end
