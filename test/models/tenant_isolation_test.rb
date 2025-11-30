require "test_helper"

class TenantIsolationTest < ActiveSupport::TestCase
  test "User A cannot see User B's servers" do
    tenant_a = "tenant-a-#{SecureRandom.hex(4)}"
    tenant_b = "tenant-b-#{SecureRandom.hex(4)}"

    TenantRecord.create_tenant(tenant_a)
    TenantRecord.create_tenant(tenant_b)

    TenantRecord.with_tenant(tenant_a) do
      Server.create!(address: "irc.libera.chat", nickname: "userA")
    end

    TenantRecord.with_tenant(tenant_b) do
      Server.create!(address: "irc.efnet.org", nickname: "userB")
    end

    TenantRecord.with_tenant(tenant_a) do
      servers = Server.all
      assert_equal 1, servers.count
      assert_equal "irc.libera.chat", servers.first.address
    end

    TenantRecord.destroy_tenant(tenant_a)
    TenantRecord.destroy_tenant(tenant_b)
  end

  test "Tenant switch scopes queries" do
    tenant_a = "tenant-c-#{SecureRandom.hex(4)}"
    tenant_b = "tenant-d-#{SecureRandom.hex(4)}"

    TenantRecord.create_tenant(tenant_a)
    TenantRecord.create_tenant(tenant_b)

    TenantRecord.with_tenant(tenant_a) do
      Server.create!(address: "irc.libera.chat", nickname: "userA")
    end

    TenantRecord.with_tenant(tenant_b) do
      Server.create!(address: "irc.efnet.org", nickname: "userB")
    end

    TenantRecord.with_tenant(tenant_a) do
      assert Server.find_by(address: "irc.libera.chat").present?
      assert_nil Server.find_by(address: "irc.efnet.org")
    end

    TenantRecord.destroy_tenant(tenant_a)
    TenantRecord.destroy_tenant(tenant_b)
  end
end
