require "test_helper"

class Notifications::ClearancesControllerTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper

  setup do
    @user = users(:joe)
    sign_in_as(@user)
    @server = @user.servers.create!(address: "irc-#{SecureRandom.hex(4)}.example.chat", nickname: "testnick")
    @channel = @server.channels.create!(name: "#test")
  end

  def create_notification(server: @server, read_at: nil)
    message = Message.create!(server: server, channel: server.channels.first, sender: "bob", content: "hey testnick", message_type: "privmsg")
    Notification.create!(message: message, reason: "highlight", read_at: read_at)
  end

  test "POST /notifications/clearance marks every unread notification as read" do
    notifications = 3.times.map { create_notification }

    post notifications_clearance_path

    assert_redirected_to notifications_path
    notifications.each { |notification| assert notification.reload.read? }
  end

  test "POST /notifications/clearance keeps the original read time of already read notifications" do
    read_at = 2.days.ago.change(usec: 0)
    notification = create_notification(read_at: read_at)

    post notifications_clearance_path

    assert_equal read_at, notification.reload.read_at
  end

  test "POST /notifications/clearance does not touch another user's notifications" do
    other_server = users(:jane).servers.create!(address: "irc-#{SecureRandom.hex(4)}.example.chat", nickname: "jane")
    other_server.channels.create!(name: "#other")
    other_notification = create_notification(server: other_server)

    post notifications_clearance_path

    assert_not other_notification.reload.read?
  end

  test "notifications page is empty and the bell count is zero after clearing" do
    create_notification
    create_notification

    post notifications_clearance_path
    follow_redirect!

    assert_select ".notification-item", count: 0
    assert_select "[data-notifications-target=badge].-hidden", text: "0"
  end

  test "notifications page shows the clear all button only when there are notifications" do
    get notifications_path
    assert_select "[data-qa='clear-notifications']", count: 0

    create_notification

    get notifications_path
    assert_select "[data-qa='clear-notifications']", count: 1
  end

  test "POST /notifications/clearance broadcasts the cleared count so badges reset" do
    create_notification

    assert_broadcast_on("user_#{@user.id}_notifications", { type: "unread_count", unread_count: 0 }) do
      post notifications_clearance_path
    end
  end
end
