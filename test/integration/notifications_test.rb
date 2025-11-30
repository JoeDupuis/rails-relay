require "test_helper"

class NotificationsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    @test_id = SecureRandom.hex(4)
  end

  def unique_address(base = "irc.example")
    "#{base}-#{@test_id}.chat"
  end

  def create_server(user: @user, nickname: "testnick")
    user.servers.create!(address: unique_address, nickname: nickname)
  end

  test "message containing nickname creates highlight notification" do
    server = create_server(nickname: "joe")

    event = {
      type: "message",
      data: {
        source: "alice!alice@host",
        target: "#ruby",
        text: "hey joe check this out"
      }
    }

    assert_difference "Notification.count", 1 do
      IrcEventHandler.handle(server, event)
    end

    notification = Notification.last
    assert_equal "highlight", notification.reason
    assert_equal "alice", notification.message.sender
  end

  test "highlight detection is case insensitive" do
    server = create_server(nickname: "Joe")

    event = {
      type: "message",
      data: {
        source: "alice!alice@host",
        target: "#ruby",
        text: "JOE: hello there"
      }
    }

    assert_difference "Notification.count", 1 do
      IrcEventHandler.handle(server, event)
    end

    assert_equal "highlight", Notification.last.reason
  end

  test "highlight uses word boundaries to avoid partial matches" do
    server = create_server(nickname: "joe")

    event = {
      type: "message",
      data: {
        source: "alice!alice@host",
        target: "#ruby",
        text: "joey is here"
      }
    }

    assert_no_difference "Notification.count" do
      IrcEventHandler.handle(server, event)
    end
  end

  test "private message creates dm notification" do
    server = create_server(nickname: "testnick")

    event = {
      type: "message",
      data: {
        source: "alice!alice@host",
        target: "testnick",
        text: "hey this is a private message"
      }
    }

    assert_difference "Notification.count", 1 do
      IrcEventHandler.handle(server, event)
    end

    notification = Notification.last
    assert_equal "dm", notification.reason
    assert_equal "alice", notification.message.sender
  end

  test "notification appears in header badge" do
    server = create_server
    channel = server.channels.create!(name: "#test")
    message = Message.create!(server: server, channel: channel, sender: "alice", content: "hey", message_type: "privmsg")
    Notification.create!(message: message, reason: "highlight")

    get root_path

    assert_response :ok
    assert_select ".notifications .badge" do |badges|
      badge = badges.first
      assert_not badge["class"].include?("-hidden"), "Badge should be visible"
      assert_equal "1", badge.text.strip
    end
  end

  test "notification badge hidden when no unread notifications" do
    get root_path

    assert_response :ok
    assert_select ".notifications .badge.-hidden"
  end

  test "clicking notification goes to message location" do
    server = create_server
    channel = server.channels.create!(name: "#test")
    message = Message.create!(server: server, channel: channel, sender: "alice", content: "hey testnick", message_type: "privmsg")
    notification = Notification.create!(message: message, reason: "highlight")

    patch notification_path(notification)

    assert_redirected_to channel_path(channel, anchor: "message_#{message.id}")
  end

  test "message from self does not create highlight notification" do
    server = create_server(nickname: "joe")

    event = {
      type: "message",
      data: {
        source: "joe!joe@host",
        target: "#ruby",
        text: "I am joe and I said joe"
      }
    }

    assert_no_difference "Notification.count" do
      IrcEventHandler.handle(server, event)
    end
  end

  test "unread notification count in header shows correct count" do
    server = create_server
    channel = server.channels.create!(name: "#test")
    3.times do |i|
      message = Message.create!(server: server, channel: channel, sender: "alice", content: "msg#{i}", message_type: "privmsg")
      Notification.create!(message: message, reason: "highlight")
    end
    message4 = Message.create!(server: server, channel: channel, sender: "alice", content: "read msg", message_type: "privmsg")
    Notification.create!(message: message4, reason: "highlight", read_at: Time.current)

    get root_path
    assert_response :ok
    assert_select ".notifications .badge" do |badges|
      badge = badges.first
      assert_equal "3", badge.text.strip
    end
  end
end
