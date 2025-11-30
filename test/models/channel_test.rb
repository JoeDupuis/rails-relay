require "test_helper"

class ChannelTest < ActiveSupport::TestCase
  setup do
    @tenant_id = "channel-test-#{SecureRandom.hex(4)}"
    TenantRecord.create_tenant(@tenant_id)
  end

  teardown do
    TenantRecord.destroy_tenant(@tenant_id)
  end

  test "validates name presence" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel = Channel.new(server: server, name: "")
      assert_not channel.valid?
      assert_includes channel.errors[:name], "can't be blank"
    end
  end

  test "validates name starts with #" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel = Channel.new(server: server, name: "#ruby")
      channel.valid?
      assert_empty channel.errors[:name]
    end
  end

  test "validates name starts with &" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel = Channel.new(server: server, name: "&local")
      channel.valid?
      assert_empty channel.errors[:name]
    end
  end

  test "validates name format rejects names without # or &" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel = Channel.new(server: server, name: "ruby")
      assert_not channel.valid?
      assert channel.errors[:name].any? { |e| e.include?("invalid") }
    end
  end

  test "validates uniqueness of name per server" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      Channel.create!(server: server, name: "#ruby")
      channel = Channel.new(server: server, name: "#ruby")
      assert_not channel.valid?
      assert_includes channel.errors[:name], "has already been taken"
    end
  end

  test "allows same channel name on different servers" do
    TenantRecord.with_tenant(@tenant_id) do
      server1 = Server.create!(address: "irc.example.com", nickname: "testnick")
      server2 = Server.create!(address: "irc.other.com", nickname: "testnick")
      Channel.create!(server: server1, name: "#ruby")
      channel = Channel.new(server: server2, name: "#ruby")
      assert channel.valid?
    end
  end

  test "unread_count returns 0 when no last_read_message_id" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel = Channel.create!(server: server, name: "#ruby")
      assert_equal 0, channel.unread_count
    end
  end

  test "unread_count returns count of messages after last_read_message_id" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel = Channel.create!(server: server, name: "#ruby")

      msg1 = channel.messages.create!(nickname: "user1", content: "Hello")
      msg2 = channel.messages.create!(nickname: "user2", content: "World")
      msg3 = channel.messages.create!(nickname: "user3", content: "!")

      channel.update!(last_read_message_id: msg1.id)

      assert_equal 2, channel.unread_count
    end
  end

  test "mark_as_read updates last_read_message_id" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel = Channel.create!(server: server, name: "#ruby")

      channel.messages.create!(nickname: "user1", content: "Hello")
      channel.messages.create!(nickname: "user2", content: "World")
      last_msg = channel.messages.create!(nickname: "user3", content: "!")

      assert_nil channel.last_read_message_id
      channel.mark_as_read
      assert_equal last_msg.id, channel.reload.last_read_message_id
    end
  end

  test "has_unread? returns false when no unread messages" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel = Channel.create!(server: server, name: "#ruby")
      assert_not channel.has_unread?
    end
  end

  test "joined scope returns only joined channels" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      joined_channel = Channel.create!(server: server, name: "#ruby", joined: true)
      left_channel = Channel.create!(server: server, name: "#python", joined: false)

      joined = Channel.joined
      assert_includes joined, joined_channel
      assert_not_includes joined, left_channel
    end
  end

  test "belongs to server" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel = Channel.create!(server: server, name: "#ruby")
      assert_equal server, channel.server
    end
  end

  test "has many channel_users with dependent destroy" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      channel = Channel.create!(server: server, name: "#ruby")
      channel.channel_users.create!(nickname: "user1")

      assert_difference "ChannelUser.count", -1 do
        channel.destroy
      end
    end
  end

  test "server has many channels with dependent destroy" do
    TenantRecord.with_tenant(@tenant_id) do
      server = Server.create!(address: "irc.example.com", nickname: "testnick")
      Channel.create!(server: server, name: "#ruby")

      assert_difference "Channel.count", -1 do
        server.destroy
      end
    end
  end
end
