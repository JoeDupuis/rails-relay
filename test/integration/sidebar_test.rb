require "test_helper"
require "webmock/minitest"

class SidebarTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
    sign_in_as(@user)
    @test_id = SecureRandom.hex(4)

    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_return(status: 202, body: "", headers: {})
  end

  def unique_address(base = "irc.example")
    "#{base}-#{@test_id}.chat"
  end

  def create_server(address: nil, connected: true)
    address ||= unique_address
    @user.servers.create!(
      address: address,
      nickname: "testnick",
      connected_at: connected ? Time.current : nil
    )
  end

  test "sidebar displays server groups" do
    server1 = create_server(address: "#{@test_id}-libera.chat")
    server2 = create_server(address: "#{@test_id}-efnet.org")
    Channel.create!(server: server1, name: "#ruby", joined: true)
    Channel.create!(server: server2, name: "#music", joined: true)

    get servers_path
    assert_response :ok
    assert_select ".servergroup", count: 2
    assert_match "#{@test_id}-libera.chat", response.body
    assert_match "#{@test_id}-efnet.org", response.body
  end

  test "sidebar shows channels under servers" do
    server = create_server
    Channel.create!(server: server, name: "#ruby", joined: true)
    Channel.create!(server: server, name: "#rails", joined: true)

    get servers_path
    assert_response :ok
    assert_select ".channel-item", minimum: 2
    assert_match "#ruby", response.body
    assert_match "#rails", response.body
  end

  test "sidebar shows unread indicators" do
    server = create_server
    channel = Channel.create!(server: server, name: "#ruby", joined: true)
    first_msg = Message.create!(server: server, channel: channel, sender: "nick", message_type: "privmsg", content: "msg0")
    channel.update!(last_read_message_id: first_msg.id)
    Message.create!(server: server, channel: channel, sender: "nick", message_type: "privmsg", content: "msg1")

    get servers_path
    assert_response :ok
    assert_select ".channel-item.-unread"
    assert_select ".badge", text: "1"
  end

  test "sidebar shows connection status indicator" do
    connected_server = create_server(address: "#{@test_id}-connected.chat", connected: true)
    disconnected_server = create_server(address: "#{@test_id}-disconnected.chat", connected: false)
    Channel.create!(server: connected_server, name: "#test1", joined: true)
    Channel.create!(server: disconnected_server, name: "#test2", joined: true)

    get servers_path
    assert_response :ok
    assert_select ".connection-indicator.-connected"
    assert_select ".connection-indicator.-disconnected"
  end

  test "clicking channel navigates to channel" do
    server = create_server
    channel = Channel.create!(server: server, name: "#ruby", joined: true)

    get channel_path(channel)
    assert_response :ok
    assert_select ".channel-view .name", text: "#ruby"
  end

  test "sidebar only shows joined channels" do
    server = create_server
    Channel.create!(server: server, name: "#joined", joined: true)
    Channel.create!(server: server, name: "#notjoined", joined: false)

    get servers_path
    assert_response :ok
    assert_select ".channel-sidebar .channel-item", text: /#joined/
    assert_select ".channel-sidebar .channel-item", text: /#notjoined/, count: 0
  end

  test "sidebar only shows current user servers" do
    my_server = create_server(address: "#{@test_id}-myserver.chat")
    Channel.create!(server: my_server, name: "#mychannel", joined: true)

    other_user = users(:jane)
    other_server = other_user.servers.create!(address: "#{@test_id}-otherserver.chat", nickname: "othernick")
    Channel.create!(server: other_server, name: "#otherchannel", joined: true)

    get servers_path
    assert_response :ok
    assert_match "#{@test_id}-myserver.chat", response.body
    assert_no_match "#{@test_id}-otherserver.chat", response.body
  end
end
