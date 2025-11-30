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
end
