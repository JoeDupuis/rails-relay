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
end
