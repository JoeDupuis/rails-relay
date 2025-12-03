class Message < ApplicationRecord
  belongs_to :server
  belongs_to :channel, optional: true
  has_one :notification, dependent: :destroy

  validates :sender, presence: true
  validates :message_type, presence: true

  after_create_commit :broadcast_message, :broadcast_sidebar_update

  def from_me?(current_nickname)
    return false if current_nickname.blank?
    sender.downcase == current_nickname.downcase
  end

  def highlight?(current_nickname)
    return false if current_nickname.blank?
    return false if from_me?(current_nickname)
    return false unless %w[privmsg action].include?(message_type)
    content.present? && content.match?(/\b#{Regexp.escape(current_nickname)}\b/i)
  end

  private

  def broadcast_message
    if channel
      broadcast_append_to channel, target: "messages"
    elsif target.present?
      broadcast_append_to [ server, :dm, target.downcase ], target: "pm_messages"
    else
      broadcast_append_to [ server, :server ], target: "server_messages"
    end
  end

  def broadcast_sidebar_update
    return unless channel
    user_id = Current.user_id || Current.user&.id
    return unless user_id

    broadcast_replace_to(
      "sidebar_#{user_id}",
      target: "channel_#{channel.id}_sidebar",
      partial: "shared/channel_sidebar_item",
      locals: { channel: channel }
    )
  end
end
