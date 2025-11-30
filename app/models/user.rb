class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  after_create :create_tenant_database

  private
    def create_tenant_database
      TenantRecord.create_tenant(id.to_s, if_not_exists: true)
    end
end
