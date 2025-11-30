require "test_helper"

class MessageTest < ActiveSupport::TestCase
  setup do
    @user = users(:joe)
  end

  test "validates sender presence" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    message = Message.new(server: server, channel: channel, sender: "", message_type: "privmsg")
    assert_not message.valid?
    assert_includes message.errors[:sender], "can't be blank"
  end

  test "validates message_type presence" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    message = Message.new(server: server, channel: channel, sender: "nick", message_type: "")
    assert_not message.valid?
    assert_includes message.errors[:message_type], "can't be blank"
  end

  test "belongs to server" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    message = Message.create!(server: server, sender: "nick", message_type: "quit")
    assert_equal server, message.server
  end

  test "belongs to channel optionally" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    message = Message.new(server: server, channel: nil, sender: "nick", message_type: "quit")
    assert message.valid?
  end

  test "has_one notification with dependent destroy" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    message = Message.create!(server: server, sender: "nick", target: "user", message_type: "privmsg", content: "hi")
    Notification.create!(message: message, reason: "dm")

    assert_difference "Notification.count", -1 do
      message.destroy
    end
  end

  test "channel message broadcasts to channel stream" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")

    message = Message.create!(server: server, channel: channel, sender: "nick", content: "Hello", message_type: "privmsg")
    assert message.persisted?
    assert_equal channel, message.channel
  end

  test "PM message has target set" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")

    message = Message.create!(server: server, sender: "nick", target: "otheruser", content: "Hello", message_type: "privmsg")
    assert message.persisted?
    assert_equal "otheruser", message.target
    assert_nil message.channel
  end

  test "server message has no channel or target" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")

    message = Message.create!(server: server, sender: "nick", content: "nick changed", message_type: "nick")
    assert message.persisted?
    assert_nil message.channel
    assert_nil message.target
  end

  test "from_me? returns true when sender matches nickname" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    message = Message.create!(server: server, sender: "testnick", content: "hello", message_type: "privmsg")

    assert message.from_me?("testnick")
  end

  test "from_me? returns true case-insensitively" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    message = Message.create!(server: server, sender: "TestNick", content: "hello", message_type: "privmsg")

    assert message.from_me?("testnick")
    assert message.from_me?("TESTNICK")
    assert message.from_me?("TestNick")
  end

  test "from_me? returns false when sender is different" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    message = Message.create!(server: server, sender: "othernick", content: "hello", message_type: "privmsg")

    assert_not message.from_me?("testnick")
  end
end
