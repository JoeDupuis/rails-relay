require "test_helper"
require "webmock/minitest"

class ServersIndexTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
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

  test "authenticated user can visit root" do
    sign_in_as(@user)

    get root_path
    assert_response :ok
  end

  test "unauthenticated user is redirected to login" do
    get root_path

    assert_redirected_to new_session_path
  end

  test "user with no servers sees add first server link" do
    sign_in_as(@user)

    get root_path
    assert_response :ok

    assert_select ".servers-index .empty a", text: "Add your first server"
  end

  test "user sees servers with connection indicators" do
    sign_in_as(@user)
    connected = @user.servers.create!(address: unique_address("connected"), nickname: "nick", connected_at: Time.current)
    disconnected = @user.servers.create!(address: unique_address("disconnected"), nickname: "nick", connected_at: nil)

    get root_path
    assert_response :ok

    assert_select ".servers-index .server-section", count: 2
    assert_select ".server-section .address", text: connected.address
    assert_select ".server-section .address", text: disconnected.address
    assert_select ".connection-indicator.-connected"
    assert_select ".connection-indicator.-disconnected"
  end

  test "user sees joined channels with user counts" do
    sign_in_as(@user)
    server = @user.servers.create!(address: unique_address("channels"), nickname: "nick", connected_at: Time.current)
    channel = Channel.create!(server: server, name: "#ruby", joined: true)
    channel.channel_users.create!(nickname: "user1")
    channel.channel_users.create!(nickname: "user2")

    get root_path
    assert_response :ok

    assert_select ".server-section .channels .row .name", text: "#ruby"
    assert_select ".server-section .channels .row .users", text: /2 users/
  end

  test "connected server shows join channel form" do
    sign_in_as(@user)
    @user.servers.create!(address: unique_address("joinform"), nickname: "nick", connected_at: Time.current)

    get root_path
    assert_response :ok

    assert_select ".server-section .channels .join input[name='channel[name]']"
  end

  test "disconnected server does not show join channel form" do
    sign_in_as(@user)
    @user.servers.create!(address: unique_address("nojoin"), nickname: "nick", connected_at: nil)

    get root_path
    assert_response :ok

    assert_select ".server-section .channels .join", count: 0
  end

  test "clicking server address link goes to server show" do
    sign_in_as(@user)
    server = @user.servers.create!(address: unique_address("link"), nickname: "nick")

    get root_path
    assert_response :ok

    assert_select ".server-section .header .address[href='#{server_path(server)}']"
  end

  test "clicking channel name link goes to channel show" do
    sign_in_as(@user)
    server = @user.servers.create!(address: unique_address("chanlink"), nickname: "nick", connected_at: Time.current)
    channel = Channel.create!(server: server, name: "#ruby", joined: true)

    get root_path
    assert_response :ok

    assert_select ".server-section .channels .row .name[href='#{channel_path(channel)}']"
  end

  test "disconnect button sends disconnect request" do
    sign_in_as(@user)
    server = @user.servers.create!(address: unique_address("disconnect"), nickname: "nick", connected_at: Time.current)

    get root_path
    assert_response :ok
    assert_select ".server-section .header form[action='#{server_connection_path(server)}']"

    delete server_connection_path(server)
    assert_redirected_to server_path(server)
    assert_requested(:delete, %r{#{Rails.configuration.irc_service_url}/internal/irc/connections/#{server.id}})
  end

  test "connect button sends connect request" do
    sign_in_as(@user)
    server = @user.servers.create!(address: unique_address("connect"), nickname: "nick", connected_at: nil)

    get root_path
    assert_response :ok
    assert_select ".server-section .header form[action='#{server_connection_path(server)}']"

    post server_connection_path(server)
    assert_redirected_to server_path(server)
    assert_requested(:post, "#{Rails.configuration.irc_service_url}/internal/irc/connections")
  end

  test "join channel form sends join request" do
    sign_in_as(@user)
    server = @user.servers.create!(address: unique_address("joinchan"), nickname: "nick", connected_at: Time.current)

    post server_channels_path(server), params: { channel: { name: "#general" } }

    channel = Channel.find_by(name: "#general")
    assert channel, "Channel should be created"
    assert_redirected_to channel_path(channel)
  end

  test "leave button sends leave request" do
    sign_in_as(@user)
    server = @user.servers.create!(address: unique_address("leave"), nickname: "nick", connected_at: Time.current)
    channel = Channel.create!(server: server, name: "#ruby", joined: true)

    get root_path
    assert_response :ok
    assert_select ".server-section .channels .row form[action='#{channel_path(channel)}']"

    delete channel_path(channel)
    assert_requested(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
  end
end
