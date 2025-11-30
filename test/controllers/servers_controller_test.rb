require "test_helper"

class ServersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    @test_id = SecureRandom.hex(4)
  end

  def unique_address(base = "irc.example")
    "#{base}-#{@test_id}.chat"
  end

  test "GET /servers returns 200" do
    get servers_path
    assert_response :ok
  end

  test "GET /servers renders server list" do
    address = unique_address("libera")
    @user.servers.create!(address: address, nickname: "testnick")

    get servers_path
    assert_response :ok
    assert_match address, response.body
  end

  test "GET /servers/new returns 200" do
    get new_server_path
    assert_response :ok
  end

  test "GET /servers/new renders form" do
    get new_server_path
    assert_response :ok
    assert_select "input[name='server[address]']"
    assert_select "input[name='server[nickname]']"
  end

  test "POST /servers with valid params creates server" do
    assert_difference -> { @user.servers.count } do
      post servers_path, params: { server: { address: unique_address, nickname: "testnick" } }
    end
  end

  test "POST /servers with valid params redirects to server show page" do
    post servers_path, params: { server: { address: unique_address, nickname: "testnick" } }
    server = @user.servers.last
    assert_redirected_to server_path(server)
  end

  test "POST /servers with missing address returns 422" do
    post servers_path, params: { server: { nickname: "testnick" } }
    assert_response :unprocessable_entity
  end

  test "POST /servers with missing address re-renders form with error" do
    post servers_path, params: { server: { nickname: "testnick" } }
    assert_select "input[name='server[address]']"
    assert_match "Address", response.body
  end

  test "POST /servers with invalid port returns 422" do
    post servers_path, params: { server: { address: unique_address, nickname: "testnick", port: 99999 } }
    assert_response :unprocessable_entity
  end

  test "POST /servers with invalid port re-renders form with error" do
    post servers_path, params: { server: { address: unique_address, nickname: "testnick", port: 99999 } }
    assert_select "input[name='server[port]']"
  end

  test "POST /servers with invalid nickname returns 422" do
    post servers_path, params: { server: { address: unique_address, nickname: "123invalid" } }
    assert_response :unprocessable_entity
  end

  test "POST /servers with invalid nickname re-renders form with error" do
    post servers_path, params: { server: { address: unique_address, nickname: "123invalid" } }
    assert_select "input[name='server[nickname]']"
  end

  test "POST /servers with duplicate address+port returns 422" do
    address = unique_address("dup")
    post servers_path, params: { server: { address: address, port: 6697, nickname: "testnick1" } }
    post servers_path, params: { server: { address: address, port: 6697, nickname: "testnick2" } }
    assert_response :unprocessable_entity
  end

  test "POST /servers with duplicate address+port re-renders form with error" do
    address = unique_address("dup")
    post servers_path, params: { server: { address: address, port: 6697, nickname: "testnick1" } }
    post servers_path, params: { server: { address: address, port: 6697, nickname: "testnick2" } }
    assert_match "already been taken", response.body
  end

  test "GET /servers/:id returns 200" do
    address = unique_address("show")
    post servers_path, params: { server: { address: address, nickname: "testnick" } }
    server = @user.servers.last

    get server_path(server)
    assert_response :ok
  end

  test "GET /servers/:id renders server details" do
    address = unique_address("show")
    post servers_path, params: { server: { address: address, nickname: "testnick" } }
    server = @user.servers.last

    get server_path(server)
    assert_match address, response.body
    assert_match "testnick", response.body
  end

  test "GET /servers/:id/edit returns 200" do
    address = unique_address("edit")
    post servers_path, params: { server: { address: address, nickname: "testnick" } }
    server = @user.servers.last

    get edit_server_path(server)
    assert_response :ok
  end

  test "GET /servers/:id/edit renders edit form" do
    address = unique_address("edit")
    post servers_path, params: { server: { address: address, nickname: "testnick" } }
    server = @user.servers.last

    get edit_server_path(server)
    assert_select "input[name='server[address]'][value='#{address}']"
  end

  test "PATCH /servers/:id with valid params updates server" do
    post servers_path, params: { server: { address: unique_address("patch"), nickname: "testnick" } }
    server = @user.servers.last

    patch server_path(server), params: { server: { nickname: "newnick" } }

    assert_equal "newnick", server.reload.nickname
  end

  test "PATCH /servers/:id with valid params redirects to server show page" do
    post servers_path, params: { server: { address: unique_address("patch"), nickname: "testnick" } }
    server = @user.servers.last

    patch server_path(server), params: { server: { nickname: "newnick" } }
    assert_redirected_to server_path(server)
  end

  test "PATCH /servers/:id with invalid params returns 422" do
    post servers_path, params: { server: { address: unique_address("patch"), nickname: "testnick" } }
    server = @user.servers.last

    patch server_path(server), params: { server: { nickname: "123invalid" } }
    assert_response :unprocessable_entity
  end

  test "PATCH /servers/:id with invalid params re-renders form with error" do
    post servers_path, params: { server: { address: unique_address("patch"), nickname: "testnick" } }
    server = @user.servers.last

    patch server_path(server), params: { server: { nickname: "123invalid" } }
    assert_select "input[name='server[nickname]']"
  end

  test "DELETE /servers/:id destroys server" do
    post servers_path, params: { server: { address: unique_address("delete"), nickname: "testnick" } }
    server = @user.servers.last

    assert_difference -> { @user.servers.count }, -1 do
      delete server_path(server)
    end
  end

  test "DELETE /servers/:id redirects to servers index" do
    post servers_path, params: { server: { address: unique_address("delete"), nickname: "testnick" } }
    server = @user.servers.last

    delete server_path(server)
    assert_redirected_to servers_path
  end

  test "GET /servers/:id shows server info" do
    server = @user.servers.create!(address: unique_address("info"), nickname: "testnick", port: 6697, ssl: true)

    get server_path(server)
    assert_response :ok
    assert_match server.address, response.body
    assert_match "6697", response.body
  end

  test "GET /servers/:id shows channels" do
    server = @user.servers.create!(address: unique_address("channels"), nickname: "testnick", connected_at: Time.current)
    Channel.create!(server: server, name: "#ruby", joined: true)
    Channel.create!(server: server, name: "#rails", joined: true)
    Channel.create!(server: server, name: "#elixir", joined: true)

    get server_path(server)
    assert_response :ok
    assert_match "#ruby", response.body
    assert_match "#rails", response.body
    assert_match "#elixir", response.body
  end

  test "GET /servers/:id shows connection status when connected" do
    server = @user.servers.create!(address: unique_address("connected"), nickname: "testnick", connected_at: Time.current)

    get server_path(server)
    assert_response :ok
    assert_match "Connected", response.body
  end

  test "GET /servers/:id shows connection status when disconnected" do
    server = @user.servers.create!(address: unique_address("disconnected"), nickname: "testnick", connected_at: nil)

    get server_path(server)
    assert_response :ok
    assert_match "Disconnected", response.body
  end

  test "GET /servers/:id shows channels list with user counts" do
    server = @user.servers.create!(address: unique_address("users"), nickname: "testnick", connected_at: Time.current)
    channel = Channel.create!(server: server, name: "#ruby", joined: true)
    ChannelUser.create!(channel: channel, nickname: "user1")
    ChannelUser.create!(channel: channel, nickname: "user2")

    get server_path(server)
    assert_response :ok
    assert_match "2 users", response.body
  end

  test "GET /servers/:id loads server messages" do
    server = @user.servers.create!(address: unique_address("messages"), nickname: "testnick")
    Message.create!(server: server, channel: nil, target: nil, sender: "irc.example.com", message_type: "notice", content: "Welcome to IRC")

    get server_path(server)
    assert_response :ok
    assert_match "Welcome to IRC", response.body
  end
end
