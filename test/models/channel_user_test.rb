require "test_helper"

class ChannelUserTest < ActiveSupport::TestCase
  setup do
    @tenant_id = "channel-user-test-#{SecureRandom.hex(4)}"
    TenantRecord.create_tenant(@tenant_id)
  end

  teardown do
    TenantRecord.destroy_tenant(@tenant_id)
  end

  test "validates nickname presence" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel = Channel.create!(server: server, name: "#ruby")
      channel_user = ChannelUser.new(channel: channel, nickname: "")
      assert_not channel_user.valid?
      assert_includes channel_user.errors[:nickname], "can't be blank"
    end
  end

  test "validates uniqueness of nickname per channel" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel = Channel.create!(server: server, name: "#ruby")
      ChannelUser.create!(channel: channel, nickname: "user1")
      channel_user = ChannelUser.new(channel: channel, nickname: "user1")
      assert_not channel_user.valid?
      assert_includes channel_user.errors[:nickname], "has already been taken"
    end
  end

  test "allows same nickname in different channels" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel1 = Channel.create!(server: server, name: "#ruby")
      channel2 = Channel.create!(server: server, name: "#python")
      ChannelUser.create!(channel: channel1, nickname: "user1")
      channel_user = ChannelUser.new(channel: channel2, nickname: "user1")
      assert channel_user.valid?
    end
  end

  test "op? returns true when modes includes o" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel = Channel.create!(server: server, name: "#ruby")
      channel_user = ChannelUser.create!(channel: channel, nickname: "user1", modes: "o")
      assert channel_user.op?
    end
  end

  test "op? returns false when modes does not include o" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel = Channel.create!(server: server, name: "#ruby")
      channel_user = ChannelUser.create!(channel: channel, nickname: "user1", modes: "v")
      assert_not channel_user.op?
    end
  end

  test "op? returns false when modes is nil" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel = Channel.create!(server: server, name: "#ruby")
      channel_user = ChannelUser.create!(channel: channel, nickname: "user1")
      assert_not channel_user.op?
    end
  end

  test "voiced? returns true when modes includes v" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel = Channel.create!(server: server, name: "#ruby")
      channel_user = ChannelUser.create!(channel: channel, nickname: "user1", modes: "v")
      assert channel_user.voiced?
    end
  end

  test "voiced? returns false when modes does not include v" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel = Channel.create!(server: server, name: "#ruby")
      channel_user = ChannelUser.create!(channel: channel, nickname: "user1", modes: "o")
      assert_not channel_user.voiced?
    end
  end

  test "voiced? returns false when modes is nil" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel = Channel.create!(server: server, name: "#ruby")
      channel_user = ChannelUser.create!(channel: channel, nickname: "user1")
      assert_not channel_user.voiced?
    end
  end

  test "ops scope returns users with o mode" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel = Channel.create!(server: server, name: "#ruby")
      op_user = ChannelUser.create!(channel: channel, nickname: "op", modes: "o")
      voiced_user = ChannelUser.create!(channel: channel, nickname: "voiced", modes: "v")
      regular_user = ChannelUser.create!(channel: channel, nickname: "regular")

      ops = channel.channel_users.ops
      assert_includes ops, op_user
      assert_not_includes ops, voiced_user
      assert_not_includes ops, regular_user
    end
  end

  test "voiced scope returns users with v mode" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel = Channel.create!(server: server, name: "#ruby")
      op_user = ChannelUser.create!(channel: channel, nickname: "op", modes: "o")
      voiced_user = ChannelUser.create!(channel: channel, nickname: "voiced", modes: "v")
      regular_user = ChannelUser.create!(channel: channel, nickname: "regular")

      voiced = channel.channel_users.voiced
      assert_not_includes voiced, op_user
      assert_includes voiced, voiced_user
      assert_not_includes voiced, regular_user
    end
  end

  test "regular scope returns users without o or v mode" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel = Channel.create!(server: server, name: "#ruby")
      op_user = ChannelUser.create!(channel: channel, nickname: "op", modes: "o")
      voiced_user = ChannelUser.create!(channel: channel, nickname: "voiced", modes: "v")
      regular_user = ChannelUser.create!(channel: channel, nickname: "regular")

      regular = channel.channel_users.regular
      assert_not_includes regular, op_user
      assert_not_includes regular, voiced_user
      assert_includes regular, regular_user
    end
  end

  test "belongs to channel" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel = Channel.create!(server: server, name: "#ruby")
      channel_user = ChannelUser.create!(channel: channel, nickname: "user1")
      assert_equal channel, channel_user.channel
    end
  end
end
