class Notification < ApplicationRecord
  belongs_to :message

  validates :reason, presence: true, inclusion: { in: %w[dm highlight] }

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc).limit(50) }
  scope :for_user, ->(user) { joins(message: :server).where(servers: { user_id: user.id }) }

  def self.mark_all_as_read!
    unread.update_all(read_at: Time.current)
  end

  after_create_commit :push_later
  after_update_commit :broadcast_unread_count, if: :saved_change_to_read_at?

  def read?
    read_at.present?
  end

  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end

  def target
    message.channel || message.server.conversations.find_by(target_nick: message.target) || message.server
  end

  def push
    payload = push_payload
    user.push_subscriptions.each { |subscription| subscription.deliver(payload) }
  end

  private

  def user
    message.server.user
  end

  def title
    reason == "dm" ? "DM from #{message.sender}" : "#{message.sender} in #{message.channel&.name}"
  end

  def push_later
    PushNotificationJob.perform_later(self) if PushSubscription.enabled? && user.push_subscriptions.exists?
  end

  def broadcast_unread_count
    user.broadcast_unread_notification_count
  end

  def push_payload
    {
      title: title,
      options: {
        body: message.content.truncate(100),
        tag: "notification-#{id}",
        data: { path: Rails.application.routes.url_helpers.polymorphic_path(target, anchor: "message_#{message.id}") }
      },
      badge: user.notifications.unread.count
    }
  end
end
