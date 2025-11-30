require "test_helper"
require "webmock/minitest"

class MessageFlowTest < ActionDispatch::IntegrationTest
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

  test "user sends message to channel" do
    server = create_connected_server
    channel = Channel.create!(server: server, name: "#ruby", joined: true)

    get channel_path(channel)
    assert_response :ok

    post channel_messages_path(channel), params: { content: "Hello everyone!" }

    message = Message.last
    assert_equal "testnick", message.sender
    assert_equal "Hello everyone!", message.content
    assert_equal "privmsg", message.message_type
    assert_equal channel, message.channel

    assert_requested(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands") do |req|
      body = JSON.parse(req.body)
      body["command"] == "privmsg" &&
        body["params"]["target"] == "#ruby" &&
        body["params"]["message"] == "Hello everyone!"
    end
  end

  test "user sends /me action" do
    server = create_connected_server
    channel = Channel.create!(server: server, name: "#ruby", joined: true)

    post channel_messages_path(channel), params: { content: "/me waves at everyone" }

    message = Message.last
    assert_equal "action", message.message_type
    assert_equal "waves at everyone", message.content

    assert_requested(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands") do |req|
      body = JSON.parse(req.body)
      body["command"] == "action" &&
        body["params"]["target"] == "#ruby" &&
        body["params"]["message"] == "waves at everyone"
    end
  end

  test "user sends PM via /msg" do
    server = create_connected_server
    channel = Channel.create!(server: server, name: "#ruby", joined: true)

    post channel_messages_path(channel), params: { content: "/msg othernick Hey there!" }

    message = Message.last
    assert_nil message.channel
    assert_equal "othernick", message.target
    assert_equal "Hey there!", message.content
    assert_equal "privmsg", message.message_type

    assert_requested(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands") do |req|
      body = JSON.parse(req.body)
      body["command"] == "privmsg" &&
        body["params"]["target"] == "othernick" &&
        body["params"]["message"] == "Hey there!"
    end
  end
end
