require "test_helper"
require "webmock/minitest"

class MessagesControllerTest < ActionDispatch::IntegrationTest
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

  def create_server(address: nil)
    address ||= unique_address
    @user.servers.create!(address: address, nickname: "testnick", connected_at: Time.current)
  end

  def create_channel(server, name: "#ruby", joined: true)
    Channel.create!(server: server, name: name, joined: joined)
  end

  test "POST /channels/:channel_id/messages creates message record" do
    server = create_server
    channel = create_channel(server)

    assert_difference -> { Message.count } do
      post channel_messages_path(channel), params: { content: "Hello world" }
    end

    message = Message.last
    assert_equal server, message.server
    assert_equal channel, message.channel
    assert_equal "testnick", message.sender
    assert_equal "Hello world", message.content
    assert_equal "privmsg", message.message_type
  end

  test "POST /channels/:channel_id/messages calls InternalApiClient.send_command" do
    server = create_server
    channel = create_channel(server)

    post channel_messages_path(channel), params: { content: "Hello world" }

    assert_requested(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands") do |req|
      body = JSON.parse(req.body)
      body["command"] == "privmsg" &&
        body["params"]["target"] == "#ruby" &&
        body["params"]["message"] == "Hello world"
    end
  end

  test "POST /channels/:channel_id/messages returns turbo stream" do
    server = create_server
    channel = create_channel(server)

    post channel_messages_path(channel), params: { content: "Hello world" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :ok
  end

  test "POST with /me command creates message with type action" do
    server = create_server
    channel = create_channel(server)

    assert_difference -> { Message.count } do
      post channel_messages_path(channel), params: { content: "/me waves" }
    end

    message = Message.last
    assert_equal "action", message.message_type
    assert_equal "waves", message.content
  end

  test "POST with /me command sends action command" do
    server = create_server
    channel = create_channel(server)

    post channel_messages_path(channel), params: { content: "/me waves" }

    assert_requested(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands") do |req|
      body = JSON.parse(req.body)
      body["command"] == "action" &&
        body["params"]["target"] == "#ruby" &&
        body["params"]["message"] == "waves"
    end
  end

  test "POST with /msg command creates message with target set" do
    server = create_server
    channel = create_channel(server)

    assert_difference -> { Message.count } do
      post channel_messages_path(channel), params: { content: "/msg othernick hello there" }
    end

    message = Message.last
    assert_equal "privmsg", message.message_type
    assert_equal "hello there", message.content
    assert_equal "othernick", message.target
    assert_nil message.channel
  end

  test "POST with /msg command sends to correct nick" do
    server = create_server
    channel = create_channel(server)

    post channel_messages_path(channel), params: { content: "/msg othernick hello there" }

    assert_requested(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands") do |req|
      body = JSON.parse(req.body)
      body["command"] == "privmsg" &&
        body["params"]["target"] == "othernick" &&
        body["params"]["message"] == "hello there"
    end
  end

  test "POST with /notice command sends notice" do
    server = create_server
    channel = create_channel(server)

    post channel_messages_path(channel), params: { content: "/notice someone hello" }

    assert_requested(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands") do |req|
      body = JSON.parse(req.body)
      body["command"] == "notice" &&
        body["params"]["target"] == "someone" &&
        body["params"]["message"] == "hello"
    end
  end

  test "POST with /nick command sends nick change" do
    server = create_server
    channel = create_channel(server)

    post channel_messages_path(channel), params: { content: "/nick newnick" }

    assert_requested(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands") do |req|
      body = JSON.parse(req.body)
      body["command"] == "nick" && body["params"]["nickname"] == "newnick"
    end
  end

  test "POST with /topic command sends topic change" do
    server = create_server
    channel = create_channel(server)

    post channel_messages_path(channel), params: { content: "/topic New channel topic" }

    assert_requested(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands") do |req|
      body = JSON.parse(req.body)
      body["command"] == "topic" &&
        body["params"]["channel"] == "#ruby" &&
        body["params"]["topic"] == "New channel topic"
    end
  end

  test "POST with /part command sends part and redirects to server" do
    server = create_server
    channel = create_channel(server)

    post channel_messages_path(channel), params: { content: "/part" }

    assert_requested(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands") do |req|
      body = JSON.parse(req.body)
      body["command"] == "part" && body["params"]["channel"] == "#ruby"
    end

    assert_redirected_to server_path(server)
  end

  test "POST with unknown command shows error" do
    server = create_server
    channel = create_channel(server)

    assert_no_difference -> { Message.count } do
      post channel_messages_path(channel), params: { content: "/unknown something" }
    end

    assert_redirected_to channel_path(channel)
    follow_redirect!
    assert_match "Unknown command", response.body
  end

  test "POST when server not connected does not create message" do
    server = create_server
    channel = create_channel(server)
    WebMock.reset!
    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_return(status: 404, body: "", headers: {})

    assert_no_difference -> { Message.count } do
      post channel_messages_path(channel), params: { content: "Hello world" }
    end

    assert_redirected_to server_path(server)
  end

  test "POST when server not connected marks server as disconnected" do
    server = create_server
    channel = create_channel(server)
    channel2 = create_channel(server, name: "#test")
    WebMock.reset!
    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_return(status: 404, body: "", headers: {})

    assert server.connected?

    post channel_messages_path(channel), params: { content: "Hello world" }

    server.reload
    assert_not server.connected?
    assert_not channel.reload.joined
    assert_not channel2.reload.joined
    assert_redirected_to server_path(server)
    follow_redirect!
    assert_match "Connection lost", response.body
  end

  test "POST when IRC service unavailable does not create message" do
    server = create_server
    channel = create_channel(server)
    WebMock.reset!
    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_raise(Errno::ECONNREFUSED)

    assert_no_difference -> { Message.count } do
      post channel_messages_path(channel), params: { content: "Hello world" }
    end
  end

  test "POST when IRC service unavailable does not disconnect server" do
    server = create_server
    channel = create_channel(server)
    WebMock.reset!
    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_raise(Errno::ECONNREFUSED)

    assert server.connected?

    post channel_messages_path(channel), params: { content: "Hello world" }

    server.reload
    assert server.connected?
    follow_redirect!
    assert_match "service unavailable", response.body
  end

  test "user can only send messages to their own channels" do
    server = create_server
    channel = create_channel(server)

    sign_out
    other_user = users(:jane)
    sign_in_as(other_user)

    post channel_messages_path(channel), params: { content: "Hello" }
    assert_response :not_found
  end

  test "POST /servers/:server_id/messages creates message for PM" do
    server = create_server

    assert_difference -> { Message.count } do
      post server_messages_path(server), params: { content: "Hello", target: "somenick" }
    end

    message = Message.last
    assert_equal server, message.server
    assert_nil message.channel
    assert_equal "somenick", message.target
    assert_equal "Hello", message.content
  end

  test "POST with /msg command creates conversation" do
    server = create_server
    channel = create_channel(server)

    assert_difference -> { Conversation.count } do
      post channel_messages_path(channel), params: { content: "/msg bob hello there" }
    end

    conversation = Conversation.last
    assert_equal server, conversation.server
    assert_equal "bob", conversation.target_nick
  end

  test "POST with /msg command updates conversation last_message_at" do
    server = create_server
    channel = create_channel(server)
    conversation = Conversation.create!(server: server, target_nick: "bob", last_message_at: 1.day.ago)

    post channel_messages_path(channel), params: { content: "/msg bob hi again" }

    assert_in_delta Time.current, conversation.reload.last_message_at, 2.seconds
  end

  test "POST with /msg command finds existing conversation" do
    server = create_server
    channel = create_channel(server)
    existing = Conversation.create!(server: server, target_nick: "bob")

    assert_no_difference -> { Conversation.count } do
      post channel_messages_path(channel), params: { content: "/msg bob hello" }
    end

    assert_in_delta Time.current, existing.reload.last_message_at, 2.seconds
  end

  test "POST /channels/:id/messages with file creates message with file attached" do
    server = create_server
    channel = create_channel(server)

    file = fixture_file_upload("test.png", "image/png")

    assert_difference -> { Message.count } do
      post channel_messages_path(channel), params: { message: { file: file } }
    end

    assert_response :ok
    message = Message.last
    assert message.file.attached?
    assert_equal "image/png", message.file.content_type
  end

  test "POST /channels/:id/messages with invalid file type shows error" do
    server = create_server
    channel = create_channel(server)

    file = fixture_file_upload("test.pdf", "application/pdf")

    assert_no_difference -> { Message.count } do
      post channel_messages_path(channel), params: { message: { file: file } }
    end

    assert_redirected_to channel_path(channel)
    follow_redirect!
    assert_match "must be PNG, JPEG, GIF, or WebP", response.body
  end

  test "POST /channels/:id/messages with oversized file shows error" do
    server = create_server
    channel = create_channel(server)

    large_data = "x" * 15.megabytes
    file = Rack::Test::UploadedFile.new(StringIO.new(large_data), "image/png", true, original_filename: "large.png")

    assert_no_difference -> { Message.count } do
      post channel_messages_path(channel), params: { message: { file: file } }
    end

    assert_redirected_to channel_path(channel)
    follow_redirect!
    assert_match "must be less than 10MB", response.body
  end
end
