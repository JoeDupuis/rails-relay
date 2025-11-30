class Message < ApplicationRecord
  belongs_to :server
  belongs_to :channel, optional: true
  has_one :notification, dependent: :destroy

  validates :sender, presence: true
  validates :message_type, presence: true

  after_create_commit :broadcast_message

  def from_me?(current_nickname)
    sender.downcase == current_nickname.downcase
  end

  private

  def broadcast_message
    if channel
      broadcast_append_to channel, target: "messages"
    elsif target.present?
      broadcast_append_to [ server, :pms ], target: "pm_messages"
    else
      broadcast_append_to [ server, :server ], target: "server_messages"
    end
  end
end
