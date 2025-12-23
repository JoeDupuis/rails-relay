class Server < ApplicationRecord
  include Turbo::Broadcastable

  belongs_to :user
  encrypts :auth_password

  has_many :channels, dependent: :destroy
  has_many :channel_users, through: :channels
  has_many :conversations, dependent: :destroy
  has_many :messages, dependent: :destroy

  validates :address, presence: true, uniqueness: { scope: [ :user_id, :port ] }
  validates :port, presence: true, numericality: { only_integer: true, in: 1..65535 }
  validates :nickname, presence: true, format: { with: /\A[a-zA-Z][a-zA-Z0-9_\-\[\]\\`^{}]+\z/ }
  validates :auth_method, inclusion: { in: %w[none pass] }
  validates :auth_password, presence: true, if: -> { auth_method.present? && auth_method != "none" }

  before_validation :set_defaults
  after_update_commit :broadcast_nickname_change, if: :saved_change_to_nickname?
  after_update_commit :broadcast_connection_status, if: :saved_change_to_connected_at?

  def connected?
    connected_at.present?
  end

  def mark_disconnected!
    transaction do
      update!(connected_at: nil)
      channels.update_all(joined: false)
      ChannelUser.joins(:channel).where(channels: { server_id: id }).delete_all
    end
  end

  private

  def set_defaults
    self.port = 6697 if port.blank?
    self.ssl = true if ssl.nil?
    self.ssl_verify = true if ssl_verify.nil?
    self.auth_method ||= "none"
    self.username = nickname if username.blank?
    self.realname = nickname if realname.blank?
  end

  def broadcast_nickname_change
    broadcast_replace_to(
      self,
      target: "nickname_server_#{id}",
      html: "<p class=\"nickname\" id=\"nickname_server_#{id}\">as <strong>#{nickname}</strong></p>"
    )
  end

  def broadcast_connection_status
    broadcast_replace_to(self, target: "status_server_#{id}", partial: "servers/status", locals: { server: self })
    broadcast_replace_to(self, target: "actions_server_#{id}", partial: "servers/actions", locals: { server: self })
    broadcast_replace_to(self, target: "join_server_#{id}", partial: "servers/join", locals: { server: self })

    broadcast_replace_to(self, target: "flash_notice", html: "")
    broadcast_replace_to(self, target: "flash_alert", html: "")

    broadcast_replace_to(
      "sidebar_#{user_id}",
      target: "server_#{id}_indicator",
      partial: "shared/connection_indicator",
      locals: { server: self }
    )
  end
end
