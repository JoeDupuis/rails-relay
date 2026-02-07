class Message < ApplicationRecord
  belongs_to :server
  belongs_to :channel, optional: true
  has_one :notification, dependent: :destroy
  has_one_attached :file

  validates :sender, presence: true
  validates :message_type, presence: true
  validate :validate_file_type, if: -> { file.attached? }
  validate :validate_file_size, if: -> { file.attached? }

  after_create_commit :set_content_from_file, :broadcast_message, :broadcast_sidebar_update, :send_file_to_irc

  ALLOWED_FILE_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze
  MAX_FILE_SIZE = 10.megabytes

  def self.create_outgoing!(server:, parts:, target:, message_type:)
    parts.map do |part|
      create!(
        server: server,
        channel: target.is_a?(Channel) ? target : nil,
        target: target.is_a?(Channel) ? nil : target,
        sender: server.nickname,
        content: part,
        message_type: message_type
      )
    end
  end

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

  def validate_file_type
    return unless file.attached?
    unless ALLOWED_FILE_TYPES.include?(file.content_type)
      errors.add(:file, "must be PNG, JPEG, GIF, or WebP")
    end
  end

  def validate_file_size
    return unless file.attached?
    if file.byte_size > MAX_FILE_SIZE
      errors.add(:file, "must be less than 10MB")
    end
  end

  def set_content_from_file
    return unless file.attached?
    return unless channel

    update_column(:content, Rails.application.routes.url_helpers.rails_blob_url(file))
  end

  def send_file_to_irc
    return unless file.attached?
    return unless channel

    InternalApiClient.send_command(
      server_id: server_id,
      command: "privmsg",
      params: { target: channel.name, message: content }
    )
  rescue InternalApiClient::ConnectionNotFound, InternalApiClient::ServiceUnavailable
  end
end
