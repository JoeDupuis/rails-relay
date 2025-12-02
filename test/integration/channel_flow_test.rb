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

    assert_select ".user-item.-op .nick", text: "op_user"
    assert_select ".user-item.-voice .nick", text: "voiced_user"
    assert_select ".user-item .nick", text: "regular_user"

    op_position = response.body.index("op_user")
    voiced_position = response.body.index("voiced_user")
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

  test "channel page shows correct user count" do
    server = create_connected_server
    channel = Channel.create!(server: server, name: "#ruby", joined: true)
    channel.channel_users.create!(nickname: "user1", modes: "o")
    channel.channel_users.create!(nickname: "user2", modes: "v")
    channel.channel_users.create!(nickname: "user3")

    get channel_path(channel)
    assert_response :ok
    assert_select ".user-list .header", text: /3 users/
  end

  test "names event populates user list" do
    server = create_connected_server
    channel = Channel.create!(server: server, name: "#ruby", joined: true)

    post internal_irc_events_path, params: {
      server_id: server.id,
      user_id: @user.id,
      event: {
        type: "names",
        data: {
          channel: "#ruby",
          names: [ "@op_user", "+voiced_user", "regular_user" ]
        }
      }
    }, headers: { "Authorization" => "Bearer #{ENV['INTERNAL_API_SECRET']}" }

    channel.reload
    assert_equal 3, channel.channel_users.count
    assert channel.channel_users.exists?(nickname: "op_user", modes: "o")
    assert channel.channel_users.exists?(nickname: "voiced_user", modes: "v")
    assert channel.channel_users.exists?(nickname: "regular_user")

    get channel_path(channel)
    assert_response :ok
    assert_select ".user-item.-op .nick", text: "op_user"
    assert_select ".user-item.-voice .nick", text: "voiced_user"
    assert_select ".user-item .nick", text: "regular_user"
  end

  test "user list updates when user joins" do
    server = create_connected_server
    channel = Channel.create!(server: server, name: "#ruby", joined: true)
    channel.channel_users.create!(nickname: "existing_user")

    post internal_irc_events_path, params: {
      server_id: server.id,
      user_id: @user.id,
      event: {
        type: "join",
        data: {
          source: "newuser!user@host",
          target: "#ruby"
        }
      }
    }, headers: { "Authorization" => "Bearer #{ENV['INTERNAL_API_SECRET']}" }

    channel.reload
    assert_equal 2, channel.channel_users.count
    assert channel.channel_users.exists?(nickname: "newuser")
  end

  test "user list updates when user parts" do
    server = create_connected_server
    channel = Channel.create!(server: server, name: "#ruby", joined: true)
    channel.channel_users.create!(nickname: "user1")
    channel.channel_users.create!(nickname: "user2")

    post internal_irc_events_path, params: {
      server_id: server.id,
      user_id: @user.id,
      event: {
        type: "part",
        data: {
          source: "user1!user@host",
          target: "#ruby",
          text: "Leaving"
        }
      }
    }, headers: { "Authorization" => "Bearer #{ENV['INTERNAL_API_SECRET']}" }

    channel.reload
    assert_equal 1, channel.channel_users.count
    assert_not channel.channel_users.exists?(nickname: "user1")
    assert channel.channel_users.exists?(nickname: "user2")
  end

  test "user joins channel without typing #" do
    server = create_connected_server

    get server_path(server)
    assert_response :ok
    assert_select "input[name='channel[name]']"

    post server_channels_path(server), params: { channel: { name: "general" } }

    channel = Channel.find_by(name: "#general")
    assert channel, "Channel should be created with name #general"
    assert_redirected_to channel_path(channel)

    assert_requested(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands") do |req|
      body = JSON.parse(req.body)
      body["command"] == "join" && body["params"]["channel"] == "#general"
    end

    follow_redirect!
    assert_response :ok
    assert_match "#general", response.body
  end

  test "disconnect resets channel state" do
    server = create_connected_server
    channel1 = Channel.create!(server: server, name: "#ruby", joined: true)
    channel2 = Channel.create!(server: server, name: "#python", joined: true)
    channel1.channel_users.create!(nickname: "user1")
    channel1.channel_users.create!(nickname: "user2")
    channel2.channel_users.create!(nickname: "user3")

    post internal_irc_events_path, params: {
      server_id: server.id,
      user_id: @user.id,
      event: { type: "disconnected" }
    }, headers: { "Authorization" => "Bearer #{ENV['INTERNAL_API_SECRET']}" }

    assert_not channel1.reload.joined
    assert_not channel2.reload.joined
    assert_equal 0, channel1.channel_users.count
    assert_equal 0, channel2.channel_users.count
  end

  test "channel view after disconnect shows not-joined state" do
    server = create_connected_server
    channel = Channel.create!(server: server, name: "#ruby", joined: true)
    channel.channel_users.create!(nickname: "user1")

    post internal_irc_events_path, params: {
      server_id: server.id,
      user_id: @user.id,
      event: { type: "disconnected" }
    }, headers: { "Authorization" => "Bearer #{ENV['INTERNAL_API_SECRET']}" }

    get channel_path(channel)
    assert_response :ok
    assert_match "not in this channel", response.body
    assert_select "form[action='#{server_channels_path(server)}'] input[value='Join']"
  end

  test "channel view when not joined but connected shows disabled input" do
    server = create_connected_server
    channel = Channel.create!(server: server, name: "#ruby", joined: false)

    get channel_path(channel)
    assert_response :ok
    assert_select ".message-input .field[disabled]"
    assert_match "not in this channel", response.body
    assert_select "form[action='#{server_channels_path(server)}'] input[value='Join']"
  end
end
