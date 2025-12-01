require "test_helper"
require "webmock/minitest"

class ServerPageTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    @test_id = SecureRandom.hex(4)

    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/connections")
      .to_return(status: 202, body: "", headers: {})
    stub_request(:delete, %r{#{Rails.configuration.irc_service_url}/internal/irc/connections/\d+})
      .to_return(status: 202, body: "", headers: {})
    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_return(status: 202, body: "", headers: {})
  end

  def unique_address(base = "irc.example")
    "#{base}-#{@test_id}.chat"
  end

  test "user views server details" do
    server = @user.servers.create!(address: unique_address("view"), nickname: "testnick", port: 6697, ssl: true)

    get server_path(server)
    assert_response :ok

    assert_match server.address, response.body
    assert_match "6697", response.body
    assert_match "SSL", response.body
  end

  test "user views server connection status" do
    connected_server = @user.servers.create!(address: unique_address("connected"), nickname: "testnick", connected_at: Time.current)
    disconnected_server = @user.servers.create!(address: unique_address("disconnected"), nickname: "testnick", connected_at: nil)

    get server_path(connected_server)
    assert_response :ok
    assert_match "Connected", response.body

    get server_path(disconnected_server)
    assert_response :ok
    assert_match "Disconnected", response.body
  end

  test "user can connect from server page" do
    server = @user.servers.create!(address: unique_address("connect"), nickname: "testnick", connected_at: nil)

    get server_path(server)
    assert_response :ok
    assert_select "form[action='#{server_connection_path(server)}'][method='post']"

    post server_connection_path(server)
    assert_redirected_to server_path(server)

    assert_requested(:post, "#{Rails.configuration.irc_service_url}/internal/irc/connections")
  end

  test "user can join channel from server page" do
    server = @user.servers.create!(address: unique_address("join"), nickname: "testnick", connected_at: Time.current)

    get server_path(server)
    assert_response :ok
    assert_select "input[name='channel[name]']"

    post server_channels_path(server), params: { channel: { name: "#ruby" } }

    channel = Channel.find_by(name: "#ruby")
    assert channel, "Channel should be created"
    assert_redirected_to channel_path(channel)
  end

  test "server page shows joined channels" do
    server = @user.servers.create!(address: unique_address("channels"), nickname: "testnick", connected_at: Time.current)
    channel1 = Channel.create!(server: server, name: "#ruby", joined: true)
    channel2 = Channel.create!(server: server, name: "#python", joined: true)
    channel1.channel_users.create!(nickname: "user1")
    channel1.channel_users.create!(nickname: "user2")
    channel2.channel_users.create!(nickname: "user1")

    get server_path(server)
    assert_response :ok

    assert_select ".server-view .channels .list .row" do
      assert_select ".name", text: "#python"
      assert_select ".name", text: "#ruby"
    end
    assert_select ".row .users", text: /2/
    assert_select ".row .users", text: /1/
  end

  test "server page hides parted channels" do
    server = @user.servers.create!(address: unique_address("parted"), nickname: "testnick", connected_at: Time.current)
    Channel.create!(server: server, name: "#active", joined: true)
    Channel.create!(server: server, name: "#inactive", joined: false)

    get server_path(server)
    assert_response :ok

    assert_select ".channels .row .name", text: "#active"
    assert_select ".channels .row .name", text: "#inactive", count: 0
  end

  test "channel list updates after join event" do
    server = @user.servers.create!(address: unique_address("joinevent"), nickname: "testnick", connected_at: Time.current)

    get server_path(server)
    assert_response :ok
    assert_select ".channels .row .name", count: 0

    IrcEventHandler.handle(server, {
      type: "join",
      data: { source: "testnick!user@host", target: "#newchannel" }
    })

    get server_path(server)
    assert_response :ok
    assert_select ".channels .row .name", text: "#newchannel"
  end
end
