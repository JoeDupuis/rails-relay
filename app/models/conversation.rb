class Conversation < ApplicationRecord
  include Turbo::Broadcastable

  belongs_to :server

  validates :target_nick, presence: true
  validates :target_nick, uniqueness: { scope: :server_id }

  def display_name
    target_nick
  end

  def subtitle
    "Direct Message"
  end

  after_create_commit :broadcast_sidebar_add
  after_update_commit :broadcast_sidebar_update, if: :saved_change_to_last_message_at?

  def messages
    Message.where(server: server, channel_id: nil, target: target_nick)
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

  private

  def broadcast_sidebar_add
    return unless server.user_id

    broadcast_append_to(
      "sidebar_#{server.user_id}",
      target: "server_#{server.id}_dms",
      partial: "shared/conversation_sidebar_item",
      locals: { conversation: self }
    )
  end

  def broadcast_sidebar_update
    return unless server.user_id

    broadcast_replace_to(
      "sidebar_#{server.user_id}",
      target: "conversation_#{id}_sidebar",
      partial: "shared/conversation_sidebar_item",
      locals: { conversation: self }
    )
  end
end
