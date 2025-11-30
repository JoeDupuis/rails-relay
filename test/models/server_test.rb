require "test_helper"

class ServerTest < ActiveSupport::TestCase
  setup do
    @tenant_id = "server-test-#{SecureRandom.hex(4)}"
    TenantRecord.create_tenant(@tenant_id)
  end

  teardown do
    TenantRecord.destroy_tenant(@tenant_id)
  end

  test "validates presence of address" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.new(nickname: "testnick")
      assert_not server.valid?
      assert_includes server.errors[:address], "can't be blank"
    end
  end

  test "defaults port when blank string submitted" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.new(address: "irc.example.com", nickname: "testnick", port: "")
      server.valid?
      assert_equal 6697, server.port
    end
  end

  test "validates port is numeric" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.new(address: "irc.example.com", nickname: "testnick")
      server.port = "abc"
      assert_not server.valid?
      assert_includes server.errors[:port], "is not a number"
    end
  end

  test "validates port in range 1-65535" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.new(address: "irc.example.com", nickname: "testnick")

      server.port = 0
      assert_not server.valid?
      assert server.errors[:port].any? { |e| e.include?("in") || e.include?("greater") }

      server.port = 65536
      assert_not server.valid?
      assert server.errors[:port].any? { |e| e.include?("in") || e.include?("less") }

      server.port = 6697
      server.valid?
      assert_empty server.errors[:port]
    end
  end

  test "validates presence of nickname" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.new(address: "irc.example.com")
      assert_not server.valid?
      assert_includes server.errors[:nickname], "can't be blank"
    end
  end

  test "validates nickname format" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.new(address: "irc.example.com")

      server.nickname = "123abc"
      assert_not server.valid?
      assert server.errors[:nickname].any? { |e| e.include?("invalid") }

      server.nickname = "abc-def"
      server.valid?
      assert_empty server.errors[:nickname]

      server.nickname = "a"
      server.valid?
      assert_empty server.errors[:nickname]

      server.nickname = "TestNick1"
      server.valid?
      assert_empty server.errors[:nickname]
    end
  end

  test "validates uniqueness of address+port per user" do
    TenantRecord.with_tenant(@tenant_id) do
      Server.create!(address: "irc.example.com", port: 6697, nickname: "testnick1")
      server = Server.new(address: "irc.example.com", port: 6697, nickname: "testnick2")
      assert_not server.valid?
      assert_includes server.errors[:address], "has already been taken"
    end
  end

  test "validates auth_password present when auth_method is nickserv" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.new(address: "irc.example.com", nickname: "testnick", auth_method: "nickserv")
      assert_not server.valid?
      assert_includes server.errors[:auth_password], "can't be blank"
    end
  end

  test "validates auth_password present when auth_method is sasl" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.new(address: "irc.example.com", nickname: "testnick", auth_method: "sasl")
      assert_not server.valid?
      assert_includes server.errors[:auth_password], "can't be blank"
    end
  end

  test "defaults port to 6697" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.new(address: "irc.example.com", nickname: "testnick")
      server.valid?
      assert_equal 6697, server.port
    end
  end

  test "defaults ssl to true" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.new(address: "irc.example.com", nickname: "testnick")
      server.valid?
      assert_equal true, server.ssl
    end
  end

  test "defaults auth_method to none" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.new(address: "irc.example.com", nickname: "testnick")
      server.valid?
      assert_equal "none", server.auth_method
    end
  end

  test "defaults username to nickname when blank" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.new(address: "irc.example.com", nickname: "testnick")
      server.valid?
      assert_equal "testnick", server.username
    end
  end

  test "defaults realname to nickname when blank" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.new(address: "irc.example.com", nickname: "testnick")
      server.valid?
      assert_equal "testnick", server.realname
    end
  end

  test "encrypts auth_password" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(
        address: "irc.example.com",
        nickname: "testnick",
        auth_method: "nickserv",
        auth_password: "secretpassword"
      )
      server.reload
      assert_equal "secretpassword", server.auth_password
    end
  end
end
