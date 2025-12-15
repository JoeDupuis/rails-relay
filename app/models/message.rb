class Message < ApplicationRecord
  belongs_to :server
  belongs_to :channel, optional: true
  has_one :notification, dependent: :destroy
  has_one_attached :file

  validates :sender, presence: true
  validates :message_type, presence: true
  validate :validate_file_type, if: -> { file.attached? }
  validate :validate_file_size, if: -> { file.attached? }

  after_create_commit :broadcast_message, :broadcast_sidebar_update, :process_file_upload

  ALLOWED_FILE_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze
  MAX_FILE_SIZE = 10.megabytes

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

  def process_file_upload
    return unless file.attached?
    return unless channel

    url = Rails.application.routes.url_helpers.rails_blob_url(file, host: default_url_host)
    update_column(:content, url)

    begin
      InternalApiClient.send_command(
        server_id: server_id,
        command: "privmsg",
        params: { target: channel.name, message: url }
      )
    rescue InternalApiClient::ConnectionNotFound, InternalApiClient::ServiceUnavailable
    end
  end

  def default_url_host
    Rails.application.config.action_mailer.default_url_options&.dig(:host) || "localhost:3000"
  end
end
