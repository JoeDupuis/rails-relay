class Server < TenantRecord
  validates :address, presence: true
  validates :port, presence: true, numericality: { in: 1..65535 }
  validates :nickname, presence: true, format: { with: /\A[a-zA-Z][a-zA-Z0-9_\-\[\]\\`^{}|]{0,15}\z/ }
  validates :auth_password, presence: true, if: -> { auth_method.present? && auth_method != "none" }
end
