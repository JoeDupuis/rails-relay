require "test_helper"
require "webmock/minitest"

class UnreadIndicatorsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    @test_id = SecureRandom.hex(4)

    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_return(status: 202, body: "", headers: {})
  end

  def unique_address(base = "irc.example")
    "#{base}-#{@test_id}.chat"
  end

  def create_connected_server
    @user.servers.create!(address: unique_address, nickname: "testnick", connected_at: Time.current)
  end

  test "viewing channel clears unread indicator" do
    server = create_connected_server
    channel = Channel.create!(server: server, name: "#ruby", joined: true)
    Message.create!(server: server, channel: channel, sender: "other_user", message_type: "privmsg", content: "hello")

    assert channel.unread?, "Channel should have unread messages initially"

    get channel_path(channel)
    assert_response :ok

    assert_not channel.reload.unread?, "Channel should be marked as read after viewing"
  end

  test "new message makes channel unread" do
    server = create_connected_server
    channel = Channel.create!(server: server, name: "#ruby", joined: true)
    channel.mark_as_read!

    assert_not channel.unread?, "Channel should start as read"

    Message.create!(server: server, channel: channel, sender: "other_user", message_type: "privmsg", content: "new message")

    assert channel.reload.unread?, "Channel should be unread after new message"
  end

  test "sidebar partial renders unread badge with count" do
    server = create_connected_server
    channel = Channel.create!(server: server, name: "#ruby", joined: true)
    first_msg = Message.create!(server: server, channel: channel, sender: "nick", message_type: "privmsg", content: "msg0")
    channel.update!(last_read_message_id: first_msg.id)
    3.times { |i| Message.create!(server: server, channel: channel, sender: "nick", message_type: "privmsg", content: "msg#{i + 1}") }

    assert_equal 3, channel.unread_count

    content = ApplicationController.renderer.render(
      partial: "shared/channel_sidebar_item",
      locals: { channel: channel }
    )

    assert_includes content, "-unread"
    assert_includes content, "<span class=\"badge\">3</span>"
  end

  test "sidebar partial renders without badge when read" do
    server = create_connected_server
    channel = Channel.create!(server: server, name: "#ruby", joined: true)
    Message.create!(server: server, channel: channel, sender: "nick", message_type: "privmsg", content: "msg")
    channel.mark_as_read!

    content = ApplicationController.renderer.render(
      partial: "shared/channel_sidebar_item",
      locals: { channel: channel }
    )

    assert_not_includes content, "-unread"
    assert_not_includes content, "<span class=\"badge\">"
  end
end
