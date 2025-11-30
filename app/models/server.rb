class Server < ApplicationRecord
  belongs_to :user
  encrypts :auth_password

  has_many :channels, dependent: :destroy
  has_many :messages, dependent: :destroy

  validates :address, presence: true, uniqueness: { scope: [ :user_id, :port ] }
  validates :port, presence: true, numericality: { only_integer: true, in: 1..65535 }
  validates :nickname, presence: true, format: { with: /\A[a-zA-Z][a-zA-Z0-9_\-\[\]\\`^{}]{0,8}\z/ }
  validates :auth_method, inclusion: { in: %w[none nickserv sasl] }
  validates :auth_password, presence: true, if: -> { auth_method.present? && auth_method != "none" }

  before_validation :set_defaults

  private

  def set_defaults
    self.port = 6697 if port.blank?
    self.ssl = true if ssl.nil?
    self.auth_method ||= "none"
    self.username = nickname if username.blank?
    self.realname = nickname if realname.blank?
  end
end
