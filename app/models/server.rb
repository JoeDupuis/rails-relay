class Server < ApplicationRecord
  broadcasts_refreshes

  belongs_to :user
  encrypts :auth_password

  has_many :channels, dependent: :destroy
  has_many :channel_users, through: :channels
  has_many :conversations, dependent: :destroy
  has_many :messages, dependent: :destroy

  validates :address, presence: true, uniqueness: { scope: [ :user_id, :port ] }
  validates :port, presence: true, numericality: { only_integer: true, in: 1..65535 }
  validates :nickname, presence: true, format: { with: /\A[a-zA-Z][a-zA-Z0-9_\-\[\]\\`^{}]*\z/ }
  validates :auth_method, inclusion: { in: %w[none pass] }
  validates :auth_password, presence: true, if: -> { auth_method.present? && auth_method != "none" }

  before_validation :set_defaults

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
end
