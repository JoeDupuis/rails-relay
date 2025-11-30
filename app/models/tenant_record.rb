class TenantRecord < ActiveRecord::Base
  self.abstract_class = true
  tenanted "tenant"
end
