class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :servers, dependent: :destroy
  has_many :messages, through: :servers
  has_many :notifications, through: :messages
  has_many :push_subscriptions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def read_notifications!(messages)
    read = notifications.unread.where(message_id: messages.select(:id)).update_all(read_at: Time.current)
    broadcast_unread_notification_count if read.positive?
  end

  def broadcast_unread_notification_count
    ActionCable.server.broadcast(
      "user_#{id}_notifications",
      { type: "unread_count", unread_count: notifications.unread.count }
    )
  end
end
