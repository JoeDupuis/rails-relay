require "test_helper"
require "webmock/minitest"

class ChannelFlowTest < ActionDispatch::IntegrationTest
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

  test "user joins a channel" do
    server = create_connected_server

    get server_path(server)
    assert_response :ok
    assert_select "input[name='channel[name]']"

    post server_channels_path(server), params: { channel: { name: "#ruby" } }

    channel = Channel.find_by(name: "#ruby")
    assert channel, "Channel should be created"
    assert_redirected_to channel_path(channel)

    post internal_irc_events_path, params: {
      server_id: server.id,
      user_id: @user.id,
      event: { type: "join", data: { source: "testnick!user@host", target: "#ruby" } }
    }, headers: { "Authorization" => "Bearer #{ENV['INTERNAL_API_SECRET']}" }

    assert channel.reload.joined

    get server_path(server)
    assert_response :ok
    assert_match "#ruby", response.body
    assert_select "a[href='#{channel_path(channel)}']"

    get channel_path(channel)
    assert_response :ok
    assert_match "#ruby", response.body
  end

  test "user leaves a channel" do
    server = create_connected_server
    channel = Channel.create!(server: server, name: "#ruby", joined: true)

    get channel_path(channel)
    assert_response :ok
    assert_select "form[action='#{channel_path(channel)}'][method='post']"

    delete channel_path(channel)
    assert_redirected_to server_path(server)

    post internal_irc_events_path, params: {
      server_id: server.id,
      user_id: @user.id,
      event: { type: "part", data: { source: "testnick!user@host", target: "#ruby", text: "Leaving" } }
    }, headers: { "Authorization" => "Bearer #{ENV['INTERNAL_API_SECRET']}" }

    assert_not channel.reload.joined

    get server_path(server)
    assert_response :ok
    assert_no_match "a[href='#{channel_path(channel)}']", response.body
  end

  test "channel shows users with proper ordering" do
    server = create_connected_server
    channel = Channel.create!(server: server, name: "#ruby", joined: true)
    channel.channel_users.create!(nickname: "regular_user")
    channel.channel_users.create!(nickname: "voiced_user", modes: "v")
    channel.channel_users.create!(nickname: "op_user", modes: "o")

    get channel_path(channel)
    assert_response :ok

    assert_match "@op_user", response.body
    assert_match "+voiced_user", response.body
    assert_match "regular_user", response.body

    op_position = response.body.index("@op_user")
    voiced_position = response.body.index("+voiced_user")
    regular_position = response.body.index("regular_user")

    assert op_position < voiced_position, "Ops should appear before voiced users"
    assert voiced_position < regular_position, "Voiced users should appear before regular users"
  end

  test "server page shows join form only when connected" do
    connected_server = create_connected_server
    disconnected_server = @user.servers.create!(address: unique_address("disconnected"), nickname: "testnick")

    get server_path(connected_server)
    assert_response :ok
    assert_select "input[name='channel[name]']"

    get server_path(disconnected_server)
    assert_response :ok
    assert_select "input[name='channel[name]']", false
  end
end
