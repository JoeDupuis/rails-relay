require "test_helper"

class ChannelTest < ActiveSupport::TestCase
  setup do
    @user = users(:joe)
  end

  test "validates name presence" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.new(server: server, name: "")
    assert_not channel.valid?
    assert_includes channel.errors[:name], "can't be blank"
  end

  test "validates name starts with #" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.new(server: server, name: "#ruby")
    channel.valid?
    assert_empty channel.errors[:name]
  end

  test "validates name starts with &" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.new(server: server, name: "&local")
    channel.valid?
    assert_empty channel.errors[:name]
  end

  test "validates name format rejects names without # or &" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.new(server: server, name: "ruby")
    assert_not channel.valid?
    assert channel.errors[:name].any? { |e| e.include?("invalid") }
  end

  test "validates uniqueness of name per server" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    Channel.create!(server: server, name: "#ruby")
    channel = Channel.new(server: server, name: "#ruby")
    assert_not channel.valid?
    assert_includes channel.errors[:name], "has already been taken"
  end

  test "allows same channel name on different servers" do
    server1 = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    server2 = @user.servers.create!(address: "irc.other.com", nickname: "testnick")
    Channel.create!(server: server1, name: "#ruby")
    channel = Channel.new(server: server2, name: "#ruby")
    assert channel.valid?
  end

  test "unread_count returns 0 when no last_read_message_id" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    assert_equal 0, channel.unread_count
  end

  test "unread_count returns count of messages after last_read_message_id" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")

    msg1 = channel.messages.create!(server: server, sender: "user1", content: "Hello", message_type: "privmsg")
    msg2 = channel.messages.create!(server: server, sender: "user2", content: "World", message_type: "privmsg")
    msg3 = channel.messages.create!(server: server, sender: "user3", content: "!", message_type: "privmsg")

    channel.update!(last_read_message_id: msg1.id)

    assert_equal 2, channel.unread_count
  end

  test "unread_count returns 0 when fully read" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")

    msg = channel.messages.create!(server: server, sender: "user1", content: "Hello", message_type: "privmsg")
    channel.update!(last_read_message_id: msg.id)

    assert_equal 0, channel.unread_count
  end

  test "mark_as_read! updates last_read_message_id" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")

    channel.messages.create!(server: server, sender: "user1", content: "Hello", message_type: "privmsg")
    channel.messages.create!(server: server, sender: "user2", content: "World", message_type: "privmsg")
    last_msg = channel.messages.create!(server: server, sender: "user3", content: "!", message_type: "privmsg")

    assert_nil channel.last_read_message_id
    channel.mark_as_read!
    assert_equal last_msg.id, channel.reload.last_read_message_id
  end

  test "mark_as_read! makes unread? return false" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")

    channel.messages.create!(server: server, sender: "user1", content: "Hello", message_type: "privmsg")

    assert channel.unread?
    channel.mark_as_read!
    assert_not channel.reload.unread?
  end

  test "unread? returns false when no messages" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    assert_not channel.unread?
  end

  test "unread? returns true when has unread messages" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")

    channel.messages.create!(server: server, sender: "user1", content: "Hello", message_type: "privmsg")
    assert channel.unread?
  end

  test "unread? returns false when fully read" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")

    msg = channel.messages.create!(server: server, sender: "user1", content: "Hello", message_type: "privmsg")
    channel.update!(last_read_message_id: msg.id)

    assert_not channel.unread?
  end

  test "joined scope returns only joined channels" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    joined_channel = Channel.create!(server: server, name: "#ruby", joined: true)
    left_channel = Channel.create!(server: server, name: "#python", joined: false)

    joined = Channel.joined
    assert_includes joined, joined_channel
    assert_not_includes joined, left_channel
  end

  test "belongs to server" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    assert_equal server, channel.server
  end

  test "has many channel_users with dependent destroy" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    channel.channel_users.create!(nickname: "user1")

    assert_difference "ChannelUser.count", -1 do
      channel.destroy
    end
  end

  test "server has many channels with dependent destroy" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    Channel.create!(server: server, name: "#ruby")

    assert_difference "Channel.count", -1 do
      server.destroy
    end
  end
end
