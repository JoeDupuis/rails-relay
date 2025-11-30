class Channel < ApplicationRecord
  belongs_to :server
  has_many :channel_users, dependent: :destroy
  has_many :messages, dependent: :destroy

  validates :name, presence: true, format: { with: /\A[#&].+\z/ }
  validates :name, uniqueness: { scope: :server_id }

  scope :joined, -> { where(joined: true) }

  def unread_count
    return 0 unless last_read_message_id
    messages.where("id > ?", last_read_message_id).count
  end

  def unread?
    if last_read_message_id
      messages.where("id > ?", last_read_message_id).exists?
    else
      messages.exists?
    end
  end

  def mark_as_read!
    update!(last_read_message_id: messages.maximum(:id))
  end
end
