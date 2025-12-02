require "test_helper"
require "webmock/minitest"

class AutoJoinTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    @test_id = SecureRandom.hex(4)

    @server = @user.servers.create!(
      address: "irc-#{@test_id}.example.com",
      port: 6697,
      ssl: true,
      nickname: "testnick"
    )

    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_return(status: 202)
  end

  test "connected event triggers auto-join for channels with auto_join=true" do
    auto_channel = Channel.create!(server: @server, name: "#general", auto_join: true)
    Channel.create!(server: @server, name: "#random", auto_join: false)

    general_join = stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .with(body: hash_including(command: "join", params: { channel: "#general" }))
      .to_return(status: 202)

    random_join = stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .with(body: hash_including(command: "join", params: { channel: "#random" }))
      .to_return(status: 202)

    IrcEventHandler.handle(@server, { type: "connected" })

    assert_requested general_join
    assert_not_requested random_join
  end

  test "server page shows auto-join badge for auto-join channels" do
    Channel.create!(server: @server, name: "#autojoin", auto_join: true, joined: true)
    Channel.create!(server: @server, name: "#manual", auto_join: false, joined: true)

    get server_path(@server)
    assert_response :ok
    assert_select ".auto-join-badge", text: "auto", count: 1
  end

  test "server page shows auto-join toggle checkbox for channels" do
    Channel.create!(server: @server, name: "#test", auto_join: false, joined: true)

    get server_path(@server)
    assert_response :ok
    assert_select ".auto-join-form input[type='checkbox']"
  end

  test "channel page shows auto-join toggle" do
    @server.update!(connected_at: Time.current)
    channel = Channel.create!(server: @server, name: "#test", auto_join: false, joined: true)

    get channel_path(channel)
    assert_response :ok
    assert_select ".auto-join-form .auto-join-toggle"
  end

  test "toggling auto-join via PATCH updates channel" do
    channel = Channel.create!(server: @server, name: "#test", auto_join: false, joined: true)
    assert_not channel.auto_join

    patch channel_path(channel), params: { channel: { auto_join: "1" } }
    assert_redirected_to channel_path(channel)

    assert channel.reload.auto_join
  end
end
