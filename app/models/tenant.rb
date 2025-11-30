module Tenant
  def self.switch(user, &block)
    TenantRecord.with_tenant(user.id.to_s, &block)
  end
end
