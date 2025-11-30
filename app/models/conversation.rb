class Conversation < ApplicationRecord
  belongs_to :server

  validates :target_nick, presence: true
  validates :target_nick, uniqueness: { scope: :server_id }

  def messages
    Message.where(server: server, channel_id: nil)
           .where("target = ? OR sender = ?", target_nick, target_nick)
           .order(:created_at)
  end

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
