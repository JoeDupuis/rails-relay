require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
    sign_in_as(@user)
    @test_id = SecureRandom.hex(4)
  end

  def unique_address(base = "irc.example")
    "#{base}-#{@test_id}.chat"
  end

  def create_server(address: nil, user: @user)
    address ||= unique_address
    user.servers.create!(address: address, nickname: "testnick")
  end

  def create_channel(server, name: "#test")
    server.channels.create!(name: name)
  end

  def create_message(server:, channel: nil, sender: "someone", content: "hello")
    Message.create!(server: server, channel: channel, sender: sender, content: content, message_type: "privmsg")
  end

  def create_notification(message:, reason: "highlight", read_at: nil)
    Notification.create!(message: message, reason: reason, read_at: read_at)
  end

  test "GET /notifications returns 200" do
    get notifications_path
    assert_response :ok
  end

  test "GET /notifications lists unread notifications" do
    server = create_server
    channel = create_channel(server)
    message = create_message(server: server, channel: channel, sender: "bob", content: "hey testnick")
    notification = create_notification(message: message, reason: "highlight")

    get notifications_path
    assert_response :ok
    assert_select ".notification-item", count: 1
    assert_match "bob", response.body
  end

  test "GET /notifications does not list read notifications" do
    server = create_server
    channel = create_channel(server)
    message = create_message(server: server, channel: channel)
    create_notification(message: message, reason: "highlight", read_at: Time.current)

    get notifications_path
    assert_response :ok
    assert_select ".notification-item", count: 0
  end

  test "user can only see their own notifications" do
    server = create_server
    channel = create_channel(server)
    message = create_message(server: server, channel: channel)
    create_notification(message: message, reason: "highlight")

    sign_out
    other_user = users(:jane)
    sign_in_as(other_user)

    get notifications_path
    assert_response :ok
    assert_select ".notification-item", count: 0
  end

  test "PATCH /notifications/:id marks notification as read" do
    server = create_server
    channel = create_channel(server)
    message = create_message(server: server, channel: channel)
    notification = create_notification(message: message, reason: "highlight")

    assert_nil notification.read_at

    patch notification_path(notification)

    assert_not_nil notification.reload.read_at
  end

  test "PATCH /notifications/:id redirects to channel for highlight" do
    server = create_server
    channel = create_channel(server)
    message = create_message(server: server, channel: channel)
    notification = create_notification(message: message, reason: "highlight")

    patch notification_path(notification)

    assert_redirected_to channel_path(channel, anchor: "message_#{message.id}")
  end

  test "PATCH /notifications/:id redirects to conversation for dm" do
    server = create_server
    message = create_message(server: server, channel: nil, sender: "dmuser", content: "private message")
    message.update!(target: "dmuser")
    conversation = server.conversations.create!(target_nick: "dmuser")
    notification = create_notification(message: message, reason: "dm")

    patch notification_path(notification)

    assert_redirected_to conversation_path(conversation, anchor: "message_#{message.id}")
  end

  test "user cannot update another user's notification" do
    server = create_server
    channel = create_channel(server)
    message = create_message(server: server, channel: channel)
    notification = create_notification(message: message, reason: "highlight")

    sign_out
    other_user = users(:jane)
    sign_in_as(other_user)

    patch notification_path(notification)
    assert_response :not_found
  end

  test "GET /notifications shows dm notifications with Direct Message label" do
    server = create_server
    message = create_message(server: server, channel: nil, sender: "dmuser", content: "private msg")
    message.update!(target: "dmuser")
    create_notification(message: message, reason: "dm")

    get notifications_path
    assert_response :ok
    assert_match "Direct Message", response.body
  end

  test "GET /notifications shows highlight notifications with channel name" do
    server = create_server
    channel = create_channel(server, name: "#ruby-lang")
    message = create_message(server: server, channel: channel, content: "hey testnick")
    create_notification(message: message, reason: "highlight")

    get notifications_path
    assert_response :ok
    assert_match "#ruby-lang", response.body
  end

  test "GET /notifications shows message preview" do
    server = create_server
    channel = create_channel(server)
    message = create_message(server: server, channel: channel, content: "this is a very specific message content")
    create_notification(message: message, reason: "highlight")

    get notifications_path
    assert_response :ok
    assert_match "this is a very specific message content", response.body
  end
end
