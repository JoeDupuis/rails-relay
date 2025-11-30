require "test_helper"
require "webmock/minitest"

class ChannelsControllerTest < ActionDispatch::IntegrationTest
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

  def create_server(address: nil)
    address ||= unique_address
    @user.servers.create!(address: address, nickname: "testnick", connected_at: Time.current)
  end

  def create_channel(server, name: "#ruby", joined: true)
    Channel.create!(server: server, name: name, joined: joined)
  end

  test "GET /channels/:id returns 200" do
    server = create_server
    channel = create_channel(server)

    get channel_path(channel)
    assert_response :ok
  end

  test "GET /channels/:id shows channel name" do
    server = create_server
    channel = create_channel(server, name: "#ruby-test")

    get channel_path(channel)
    assert_response :ok
    assert_match "#ruby-test", response.body
  end

  test "user can only view their own channels" do
    server = create_server
    channel = create_channel(server)

    delete session_path
    other_user = users(:jane)
    post session_path, params: { email_address: other_user.email_address, password: "secret456" }

    get channel_path(channel)
    assert_response :not_found
  end

  test "POST /servers/:server_id/channels sends join command via InternalApiClient" do
    server = create_server

    assert_requested(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands", times: 0)

    post server_channels_path(server), params: { channel: { name: "#newchannel" } }

    assert_requested(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands") do |req|
      body = JSON.parse(req.body)
      body["command"] == "join" && body["params"]["channel"] == "#newchannel"
    end
  end

  test "POST /servers/:server_id/channels creates channel record" do
    server = create_server

    assert_difference -> { Channel.count } do
      post server_channels_path(server), params: { channel: { name: "#newchannel" } }
    end
  end

  test "POST /servers/:server_id/channels redirects to channel show" do
    server = create_server

    post server_channels_path(server), params: { channel: { name: "#newchannel" } }

    channel = Channel.last
    assert_redirected_to channel_path(channel)
  end

  test "POST /servers/:server_id/channels finds existing channel instead of creating duplicate" do
    server = create_server
    existing_channel = create_channel(server, name: "#existing", joined: false)

    assert_no_difference -> { Channel.count } do
      post server_channels_path(server), params: { channel: { name: "#existing" } }
    end

    assert_redirected_to channel_path(existing_channel)
  end

  test "POST /servers/:server_id/channels redirects to server with alert when service unavailable" do
    server = create_server
    WebMock.reset!
    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_raise(Errno::ECONNREFUSED)

    post server_channels_path(server), params: { channel: { name: "#newchannel" } }

    assert_redirected_to server_path(server)
    follow_redirect!
    assert_match "IRC service unavailable", response.body
  end

  test "POST /servers/:server_id/channels redirects to server with alert when connection not found" do
    server = create_server
    WebMock.reset!
    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_return(status: 404, body: "", headers: {})

    post server_channels_path(server), params: { channel: { name: "#newchannel" } }

    assert_redirected_to server_path(server)
    follow_redirect!
    assert_match "not connected", response.body
  end

  test "DELETE /channels/:id sends part command via InternalApiClient" do
    server = create_server
    channel = create_channel(server, name: "#leaveme")

    delete channel_path(channel)

    assert_requested(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands") do |req|
      body = JSON.parse(req.body)
      body["command"] == "part" && body["params"]["channel"] == "#leaveme"
    end
  end

  test "DELETE /channels/:id updates channel joined to false" do
    server = create_server
    channel = create_channel(server, joined: true)

    delete channel_path(channel)

    assert_not channel.reload.joined
  end

  test "DELETE /channels/:id redirects to server show" do
    server = create_server
    channel = create_channel(server)

    delete channel_path(channel)

    assert_redirected_to server_path(server)
  end

  test "DELETE /channels/:id redirects to channel with alert when service unavailable" do
    server = create_server
    channel = create_channel(server)
    WebMock.reset!
    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_raise(Errno::ECONNREFUSED)

    delete channel_path(channel)

    assert_redirected_to channel_path(channel)
    follow_redirect!
    assert_match "IRC service unavailable", response.body
  end

  test "DELETE /channels/:id redirects to server with alert when connection not found" do
    server = create_server
    channel = create_channel(server)
    WebMock.reset!
    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_return(status: 404, body: "", headers: {})

    delete channel_path(channel)

    assert_redirected_to server_path(server)
    follow_redirect!
    assert_match "not connected", response.body
  end

  test "GET /channels/:id loads all messages" do
    server = create_server
    channel = create_channel(server)
    5.times { |i| Message.create!(server: server, channel: channel, sender: "nick", message_type: "privmsg", content: "msg_all_#{i}") }

    get channel_path(channel)
    assert_response :ok
    channel.messages.each do |msg|
      assert_match msg.content, response.body
    end
  end

  test "GET /channels/:id orders messages oldest to newest for display" do
    server = create_server
    channel = create_channel(server)
    old = Message.create!(server: server, channel: channel, sender: "nick", message_type: "privmsg", content: "old_message_first", created_at: 2.hours.ago)
    new_msg = Message.create!(server: server, channel: channel, sender: "nick", message_type: "privmsg", content: "new_message_second", created_at: 1.hour.ago)

    get channel_path(channel)
    assert_response :ok
    old_pos = response.body.index(old.content)
    new_pos = response.body.index(new_msg.content)
    assert old_pos < new_pos, "Old message should appear before new message"
  end

  test "GET /channels/:id displays message timestamps" do
    server = create_server
    channel = create_channel(server)
    Message.create!(server: server, channel: channel, sender: "nick", message_type: "privmsg", content: "timestamped_msg")

    get channel_path(channel)
    assert_response :ok
    assert_select ".message-item .timestamp"
  end

  test "GET /channels/:id marks channel as read" do
    server = create_server
    channel = create_channel(server)
    msg = Message.create!(server: server, channel: channel, sender: "nick", message_type: "privmsg", content: "new message")

    assert_nil channel.last_read_message_id
    assert channel.unread?

    get channel_path(channel)

    assert_equal msg.id, channel.reload.last_read_message_id
    assert_not channel.unread?
  end

  test "GET /channels/:id updates last_read_message_id to latest" do
    server = create_server
    channel = create_channel(server)
    Message.create!(server: server, channel: channel, sender: "nick", message_type: "privmsg", content: "msg1")
    msg2 = Message.create!(server: server, channel: channel, sender: "nick", message_type: "privmsg", content: "msg2")

    get channel_path(channel)

    assert_equal msg2.id, channel.reload.last_read_message_id
  end
end
