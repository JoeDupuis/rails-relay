require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  setup do
    @user = users(:joe)
    @server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
  end

  test "validates target_nick presence" do
    conversation = Conversation.new(server: @server, target_nick: "")
    assert_not conversation.valid?
    assert_includes conversation.errors[:target_nick], "can't be blank"
  end

  test "validates uniqueness of target_nick per server" do
    Conversation.create!(server: @server, target_nick: "alice")
    conversation = Conversation.new(server: @server, target_nick: "alice")
    assert_not conversation.valid?
    assert_includes conversation.errors[:target_nick], "has already been taken"
  end

  test "allows same target_nick on different servers" do
    server2 = @user.servers.create!(address: "irc.other.com", nickname: "testnick")
    Conversation.create!(server: @server, target_nick: "alice")
    conversation = Conversation.new(server: server2, target_nick: "alice")
    assert conversation.valid?
  end

  test "messages returns messages for this conversation" do
    conversation = Conversation.create!(server: @server, target_nick: "alice")

    msg_from_alice = Message.create!(
      server: @server,
      channel: nil,
      target: "alice",
      sender: "alice",
      content: "Hello from alice",
      message_type: "privmsg"
    )

    msg_to_alice = Message.create!(
      server: @server,
      channel: nil,
      target: "alice",
      sender: @server.nickname,
      content: "Hello to alice",
      message_type: "privmsg"
    )

    msg_from_bob = Message.create!(
      server: @server,
      channel: nil,
      target: "bob",
      sender: "bob",
      content: "Hello from bob",
      message_type: "privmsg"
    )

    messages = conversation.messages
    assert_includes messages, msg_from_alice
    assert_includes messages, msg_to_alice
    assert_not_includes messages, msg_from_bob
  end

  test "messages does not include channel messages" do
    conversation = Conversation.create!(server: @server, target_nick: "alice")
    channel = Channel.create!(server: @server, name: "#ruby")

    pm_message = Message.create!(
      server: @server,
      channel: nil,
      target: "alice",
      sender: "alice",
      content: "PM message",
      message_type: "privmsg"
    )

    channel_message = Message.create!(
      server: @server,
      channel: channel,
      sender: "alice",
      content: "Channel message",
      message_type: "privmsg"
    )

    messages = conversation.messages
    assert_includes messages, pm_message
    assert_not_includes messages, channel_message
  end

  test "unread_count returns 0 when no last_read_message_id" do
    conversation = Conversation.create!(server: @server, target_nick: "alice")
    assert_equal 0, conversation.unread_count
  end

  test "unread_count returns count of messages after last_read_message_id" do
    conversation = Conversation.create!(server: @server, target_nick: "alice")

    msg1 = Message.create!(
      server: @server,
      channel: nil,
      target: "alice",
      sender: "alice",
      content: "Message 1",
      message_type: "privmsg"
    )

    msg2 = Message.create!(
      server: @server,
      channel: nil,
      target: "alice",
      sender: "alice",
      content: "Message 2",
      message_type: "privmsg"
    )

    msg3 = Message.create!(
      server: @server,
      channel: nil,
      target: "alice",
      sender: "alice",
      content: "Message 3",
      message_type: "privmsg"
    )

    conversation.update!(last_read_message_id: msg1.id)
    assert_equal 2, conversation.unread_count
  end

  test "mark_as_read! updates last_read_message_id" do
    conversation = Conversation.create!(server: @server, target_nick: "alice")

    Message.create!(
      server: @server,
      channel: nil,
      target: "alice",
      sender: "alice",
      content: "Message 1",
      message_type: "privmsg"
    )

    last_msg = Message.create!(
      server: @server,
      channel: nil,
      target: "alice",
      sender: "alice",
      content: "Message 2",
      message_type: "privmsg"
    )

    assert_nil conversation.last_read_message_id
    conversation.mark_as_read!
    assert_equal last_msg.id, conversation.reload.last_read_message_id
  end

  test "unread? returns true when has unread messages" do
    conversation = Conversation.create!(server: @server, target_nick: "alice")

    Message.create!(
      server: @server,
      channel: nil,
      target: "alice",
      sender: "alice",
      content: "Hello",
      message_type: "privmsg"
    )

    assert conversation.unread?
  end

  test "unread? returns false when fully read" do
    conversation = Conversation.create!(server: @server, target_nick: "alice")

    msg = Message.create!(
      server: @server,
      channel: nil,
      target: "alice",
      sender: "alice",
      content: "Hello",
      message_type: "privmsg"
    )

    conversation.update!(last_read_message_id: msg.id)
    assert_not conversation.unread?
  end

  test "unread? returns false when no messages" do
    conversation = Conversation.create!(server: @server, target_nick: "alice")
    assert_not conversation.unread?
  end

  test "belongs to server" do
    conversation = Conversation.create!(server: @server, target_nick: "alice")
    assert_equal @server, conversation.server
  end

  test "server has many conversations with dependent destroy" do
    Conversation.create!(server: @server, target_nick: "alice")

    assert_difference "Conversation.count", -1 do
      @server.destroy
    end
  end

  test "broadcasts sidebar append on create" do
    assert_turbo_stream_broadcasts "sidebar_#{@user.id}" do
      Conversation.create!(server: @server, target_nick: "alice")
    end
  end

  test "broadcasts sidebar update when last_message_at changes" do
    conversation = Conversation.create!(server: @server, target_nick: "alice")

    assert_turbo_stream_broadcasts "sidebar_#{@user.id}" do
      conversation.update!(last_message_at: Time.current)
    end
  end

  test "display_name returns target_nick" do
    conversation = Conversation.create!(server: @server, target_nick: "alice")
    assert_equal "alice", conversation.display_name
  end

  test "subtitle returns Direct Message" do
    conversation = Conversation.create!(server: @server, target_nick: "alice")
    assert_equal "Direct Message", conversation.subtitle
  end

  test "target_online? returns true when user is in a shared channel" do
    channel = Channel.create!(server: @server, name: "#ruby")
    ChannelUser.create!(channel: channel, nickname: "alice")
    conversation = Conversation.create!(server: @server, target_nick: "alice")

    assert conversation.target_online?
  end

  test "target_online? returns false when user is not in any channel" do
    Channel.create!(server: @server, name: "#ruby")
    conversation = Conversation.create!(server: @server, target_nick: "bob")

    assert_not conversation.target_online?
  end

  test "target_online? is case-insensitive" do
    channel = Channel.create!(server: @server, name: "#ruby")
    ChannelUser.create!(channel: channel, nickname: "alice")
    conversation = Conversation.create!(server: @server, target_nick: "Alice")

    assert conversation.target_online?
  end

  test "closed? returns false for new conversation" do
    conversation = Conversation.create!(server: @server, target_nick: "alice")
    assert_not conversation.closed?
  end

  test "closed? returns true when closed_at set" do
    conversation = Conversation.create!(server: @server, target_nick: "alice", closed_at: Time.current)
    assert conversation.closed?
  end

  test "close! sets closed_at" do
    conversation = Conversation.create!(server: @server, target_nick: "alice")
    assert_nil conversation.closed_at

    conversation.close!

    assert_not_nil conversation.closed_at
    assert conversation.closed?
  end

  test "close! also marks conversation as read" do
    conversation = Conversation.create!(server: @server, target_nick: "alice")
    msg = Message.create!(
      server: @server,
      channel: nil,
      target: "alice",
      sender: "alice",
      content: "Hello",
      message_type: "privmsg"
    )

    assert_nil conversation.last_read_message_id
    conversation.close!
    assert_equal msg.id, conversation.last_read_message_id
  end

  test "reopen! clears closed_at" do
    conversation = Conversation.create!(server: @server, target_nick: "alice", closed_at: Time.current)
    assert conversation.closed?

    conversation.reopen!

    assert_nil conversation.closed_at
    assert_not conversation.closed?
  end

  test "reopen! does nothing if already open" do
    conversation = Conversation.create!(server: @server, target_nick: "alice")
    assert_not conversation.closed?

    conversation.reopen!

    assert_nil conversation.closed_at
  end

  test "open scope excludes closed conversations" do
    open1 = Conversation.create!(server: @server, target_nick: "alice")
    open2 = Conversation.create!(server: @server, target_nick: "bob")
    closed1 = Conversation.create!(server: @server, target_nick: "carol", closed_at: Time.current)

    open_conversations = @server.conversations.open
    assert_includes open_conversations, open1
    assert_includes open_conversations, open2
    assert_not_includes open_conversations, closed1
  end

  test "closed scope returns only closed conversations" do
    open1 = Conversation.create!(server: @server, target_nick: "alice")
    open2 = Conversation.create!(server: @server, target_nick: "bob")
    closed1 = Conversation.create!(server: @server, target_nick: "carol", closed_at: Time.current)

    closed_conversations = @server.conversations.closed
    assert_not_includes closed_conversations, open1
    assert_not_includes closed_conversations, open2
    assert_includes closed_conversations, closed1
  end
end
