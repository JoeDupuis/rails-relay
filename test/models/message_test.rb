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

  test "from_me? returns false when nickname is blank" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    message = Message.create!(server: server, sender: "nick", content: "hello", message_type: "privmsg")

    assert_not message.from_me?(nil)
    assert_not message.from_me?("")
  end

  test "highlight? returns true when nickname mentioned in privmsg" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    message = Message.create!(server: server, sender: "alice", content: "Hey testnick, how are you?", message_type: "privmsg")

    assert message.highlight?("testnick")
  end

  test "highlight? returns true when nickname mentioned in action" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    message = Message.create!(server: server, sender: "alice", content: "waves at testnick", message_type: "action")

    assert message.highlight?("testnick")
  end

  test "highlight? returns false for own messages" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    message = Message.create!(server: server, sender: "testnick", content: "Mentioning testnick", message_type: "privmsg")

    assert_not message.highlight?("testnick")
  end

  test "highlight? returns false for non-privmsg/action types" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    message = Message.create!(server: server, sender: "alice", content: "testnick", message_type: "join")

    assert_not message.highlight?("testnick")
  end

  test "highlight? returns false when nickname not mentioned" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    message = Message.create!(server: server, sender: "alice", content: "Hello everyone!", message_type: "privmsg")

    assert_not message.highlight?("testnick")
  end

  test "highlight? uses word boundary matching" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "joe")
    message = Message.create!(server: server, sender: "alice", content: "joey is here", message_type: "privmsg")

    assert_not message.highlight?("joe")
  end

  test "highlight? is case insensitive" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    message = Message.create!(server: server, sender: "alice", content: "Hey TESTNICK!", message_type: "privmsg")

    assert message.highlight?("testnick")
    assert message.highlight?("TESTNICK")
    assert message.highlight?("TestNick")
  end

  test "highlight? returns false when nickname is blank" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    message = Message.create!(server: server, sender: "alice", content: "Hello", message_type: "privmsg")

    assert_not message.highlight?(nil)
    assert_not message.highlight?("")
  end

  test "highlight? returns false when content is blank" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    message = Message.create!(server: server, sender: "alice", content: nil, message_type: "privmsg")

    assert_not message.highlight?("testnick")
  end

  test "broadcast_sidebar_update uses sidebar stream name" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")

    Current.user_id = @user.id

    assert_turbo_stream_broadcasts "sidebar_#{@user.id}" do
      Message.create!(server: server, channel: channel, sender: "alice", content: "Hello", message_type: "privmsg")
    end
  ensure
    Current.user_id = nil
  end
end
