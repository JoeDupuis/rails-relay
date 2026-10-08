require "test_helper"
require "webmock/minitest"

class NotificationTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  setup do
    @user = users(:joe)
    @server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    @channel = @server.channels.create!(name: "#test")
    @message = @channel.messages.create!(server: @server, sender: "someone", content: "hello testnick", message_type: "privmsg")
  end

  test "belongs_to message" do
    notification = Notification.new(message: @message, reason: "highlight")
    assert notification.valid?
    assert_equal @message, notification.message
  end

  test "validates reason presence" do
    notification = Notification.new(message: @message, reason: nil)
    assert_not notification.valid?
    assert_includes notification.errors[:reason], "can't be blank"
  end

  test "validates reason inclusion" do
    notification = Notification.new(message: @message, reason: "invalid")
    assert_not notification.valid?
    assert_includes notification.errors[:reason], "is not included in the list"
  end

  test "allows dm reason" do
    notification = Notification.new(message: @message, reason: "dm")
    assert notification.valid?
  end

  test "allows highlight reason" do
    notification = Notification.new(message: @message, reason: "highlight")
    assert notification.valid?
  end

  test "scope unread returns notifications without read_at" do
    read_notification = Notification.create!(message: @message, reason: "highlight", read_at: Time.current)
    unread_notification = Notification.create!(message: @message, reason: "dm", read_at: nil)

    unread = Notification.unread
    assert_includes unread, unread_notification
    assert_not_includes unread, read_notification
  end

  test "scope recent orders by created_at desc, limits 50" do
    51.times do |i|
      Notification.create!(message: @message, reason: "highlight")
    end

    recent = Notification.recent
    assert_equal 50, recent.count
    assert recent.first.created_at >= recent.last.created_at
  end

  test "read? returns true when read_at present" do
    notification = Notification.new(message: @message, reason: "highlight", read_at: Time.current)
    assert notification.read?
  end

  test "read? returns false when read_at nil" do
    notification = Notification.new(message: @message, reason: "highlight", read_at: nil)
    assert_not notification.read?
  end

  test "mark_as_read! sets read_at" do
    notification = Notification.create!(message: @message, reason: "highlight", read_at: nil)

    assert_nil notification.read_at
    notification.mark_as_read!
    assert_not_nil notification.reload.read_at
  end

  test "mark_as_read! does not update if already read" do
    original_read_at = 1.hour.ago
    notification = Notification.create!(message: @message, reason: "highlight", read_at: original_read_at)

    notification.mark_as_read!
    assert_in_delta original_read_at, notification.reload.read_at, 1.second
  end

  test "creating a notification enqueues a push when the user has a push subscription" do
    subscribe_to_push

    assert_enqueued_with(job: PushNotificationJob) do
      Notification.create!(message: @message, reason: "highlight")
    end
  end

  test "creating a notification does not enqueue a push without a push subscription" do
    assert_no_enqueued_jobs(only: PushNotificationJob) do
      Notification.create!(message: @message, reason: "highlight")
    end
  end

  test "push delivers to every subscription of the user" do
    subscribe_to_push
    stub_request(:post, "https://push.example.com/send/abc123").to_return(status: 201)

    Notification.create!(message: @message, reason: "highlight")
    perform_enqueued_jobs

    assert_requested(:post, "https://push.example.com/send/abc123", times: 1)
  end

  test "target is the channel for a channel message" do
    notification = Notification.create!(message: @message, reason: "highlight")

    assert_equal @channel, notification.target
  end

  test "target is the conversation for a direct message" do
    conversation = @server.conversations.create!(target_nick: "alice")
    message = Message.create!(server: @server, target: "alice", sender: "alice", content: "hi", message_type: "privmsg")

    assert_equal conversation, Notification.create!(message: message, reason: "dm").target
  end

  test "mark_as_read! broadcasts the new unread count" do
    notification = Notification.create!(message: @message, reason: "highlight")

    assert_broadcast_on("user_#{@user.id}_notifications", { type: "unread_count", unread_count: 0 }) do
      notification.mark_as_read!
    end
  end

  private

  def subscribe_to_push
    @user.push_subscriptions.create!(
      endpoint: "https://push.example.com/send/abc123",
      p256dh_key: "BPVlhw23nOgbBx8WsBDlRsSwa81irMttlLOw4q29DG-2vIHzBXNZzbYZpQ9-aWCYDib3PIDpJ8Q0Ol9giHD5boM",
      auth_key: "5vR17us8wBhIdl1G4Zl_IA"
    )
  end
end
