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

  test "server page shows not-joined channels differently" do
    server = @user.servers.create!(address: unique_address("parted"), nickname: "testnick", connected_at: Time.current)
    Channel.create!(server: server, name: "#active", joined: true)
    Channel.create!(server: server, name: "#inactive", joined: false)

    get server_path(server)
    assert_response :ok

    assert_select ".channels .row .name", text: "#active"
    assert_select ".channels .row .name", text: "#inactive"

    assert_select ".channels .row" do |rows|
      active_row = rows.find { |r| r.css(".name").text == "#active" }
      inactive_row = rows.find { |r| r.css(".name").text == "#inactive" }

      assert_select active_row, ".users", text: /users/
      assert_select active_row, "a.link", text: "View"

      assert_select inactive_row, ".status", text: "(not joined)"
      assert_select inactive_row, "input[value='Join']"
    end
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

  test "server page shows updated nickname after nick change" do
    server = @user.servers.create!(address: unique_address("nickchange"), nickname: "joe", connected_at: Time.current)

    get server_path(server)
    assert_response :ok
    assert_match /as.*<strong>joe<\/strong>/, response.body

    IrcEventHandler.handle(server, {
      type: "nick",
      data: { source: "joe!joe@host", new_nick: "joe_" }
    })

    get server_path(server)
    assert_response :ok
    assert_match /as.*<strong>joe_<\/strong>/, response.body
  end

  test "server nickname updates from server-forced nick change" do
    server = @user.servers.create!(address: unique_address("forcenick"), nickname: "joe", connected_at: Time.current)

    IrcEventHandler.handle(server, {
      type: "nick",
      data: { source: "joe!joe@host", new_nick: "joe_123" }
    })

    get server_path(server)
    assert_response :ok
    assert_match /as.*<strong>joe_123<\/strong>/, response.body
  end

  test "server page updates on connect event" do
    server = @user.servers.create!(address: unique_address("connectevent"), nickname: "testnick", connected_at: nil)

    get server_path(server)
    assert_response :ok
    assert_select ".indicator.-disconnected", text: /Disconnected/
    assert_match /Connect/, response.body
    refute_match /Join Channel/, response.body

    IrcEventHandler.handle(server, { type: "connected", data: {} })

    get server_path(server)
    assert_response :ok
    assert_select ".indicator.-connected", text: /Connected/
    assert_match /Disconnect/, response.body
    assert_match /Join Channel/, response.body
  end

  test "server page updates on disconnect event" do
    server = @user.servers.create!(address: unique_address("disconnectevent"), nickname: "testnick", connected_at: Time.current)

    get server_path(server)
    assert_response :ok
    assert_select ".indicator.-connected", text: /Connected/
    assert_match /Disconnect/, response.body
    assert_match /Join Channel/, response.body

    IrcEventHandler.handle(server, { type: "disconnected", data: {} })

    get server_path(server)
    assert_response :ok
    assert_select ".indicator.-disconnected", text: /Disconnected/
    assert_match /Connect/, response.body
    refute_match /Join Channel/, response.body
  end

  test "flash is cleared when connection completes" do
    server = @user.servers.create!(address: unique_address("flashconnect"), nickname: "testnick", connected_at: nil)

    post server_connection_path(server)
    follow_redirect!
    assert_select "#flash_notice .notice", text: "Connecting..."

    assert_turbo_stream_broadcasts(server) do
      IrcEventHandler.handle(server, { type: "connected", data: {} })
    end
  end

  test "flash is cleared when disconnection completes" do
    server = @user.servers.create!(address: unique_address("flashdisconnect"), nickname: "testnick", connected_at: Time.current)

    delete server_connection_path(server)
    follow_redirect!
    assert_select "#flash_notice .notice", text: "Disconnecting..."

    assert_turbo_stream_broadcasts(server) do
      IrcEventHandler.handle(server, { type: "disconnected", data: {} })
    end
  end

  test "channel name links to channel show page" do
    server = @user.servers.create!(address: unique_address("chanlink"), nickname: "testnick", connected_at: Time.current)
    channel = Channel.create!(server: server, name: "#ruby", joined: true)

    get server_path(server)
    assert_response :ok
    assert_select ".channels .row a.name[href='#{channel_path(channel)}']", text: "#ruby"
  end

  test "channel name links to show even when not joined" do
    server = @user.servers.create!(address: unique_address("chanlinknotjoined"), nickname: "testnick", connected_at: Time.current)
    channel = Channel.create!(server: server, name: "#ruby", joined: false)

    get server_path(server)
    assert_response :ok
    assert_select ".channels .row a.name[href='#{channel_path(channel)}']", text: "#ruby"
  end

  test "nickname broadcasts Turbo Stream update when changed" do
    server = @user.servers.create!(address: unique_address("nickbroadcast"), nickname: "joe", connected_at: Time.current)

    assert_turbo_stream_broadcasts server do
      IrcEventHandler.handle(server, {
        type: "nick",
        data: { source: "joe!joe@host", new_nick: "joe_" }
      })
    end
  end
end
