require "test_helper"
require "webmock/minitest"

class PmFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
    sign_in_as(@user)
    @test_id = SecureRandom.hex(4)

    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_return do |request|
        body = JSON.parse(request.body)
        message = body.dig("params", "message")
        parts = message ? [ message ] : true
        { status: 202, body: { parts: parts }.to_json, headers: { "Content-Type" => "application/json" } }
      end

    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/events")
      .to_return(status: 200, body: "", headers: {})
  end

  def unique_address(base = "irc.example")
    "#{base}-#{@test_id}.chat"
  end

  def create_server(address: nil)
    address ||= unique_address
    @user.servers.create!(address: address, nickname: "testnick", connected_at: Time.current)
  end

  test "receiving a PM creates conversation" do
    server = create_server

    assert_difference -> { Conversation.count } do
      post internal_irc_events_path, params: {
        server_id: server.id,
        user_id: @user.id,
        event: {
          type: "message",
          data: {
            source: "alice!user@host",
            target: "testnick",
            text: "Hello there!"
          }
        }
      }, headers: {
        "Authorization" => "Bearer #{ENV['INTERNAL_API_SECRET']}"
      }
    end

    conversation = Conversation.last
    assert_equal "alice", conversation.target_nick
    assert_equal server, conversation.server
  end

  test "receiving a PM from same person does not create duplicate conversation" do
    server = create_server
    Conversation.create!(server: server, target_nick: "alice")

    assert_no_difference -> { Conversation.count } do
      post internal_irc_events_path, params: {
        server_id: server.id,
        user_id: @user.id,
        event: {
          type: "message",
          data: {
            source: "alice!user@host",
            target: "testnick",
            text: "Hello again!"
          }
        }
      }, headers: {
        "Authorization" => "Bearer #{ENV['INTERNAL_API_SECRET']}"
      }
    end
  end

  test "receiving a PM updates conversation last_message_at" do
    server = create_server
    conversation = Conversation.create!(server: server, target_nick: "alice", last_message_at: 1.hour.ago)

    post internal_irc_events_path, params: {
      server_id: server.id,
      user_id: @user.id,
      event: {
        type: "message",
        data: {
          source: "alice!user@host",
          target: "testnick",
          text: "New message"
        }
      }
    }, headers: {
      "Authorization" => "Bearer #{ENV['INTERNAL_API_SECRET']}"
    }

    assert conversation.reload.last_message_at > 1.minute.ago
  end

  test "sidebar displays DMs section when conversations exist" do
    server = create_server
    Conversation.create!(server: server, target_nick: "alice")
    Channel.create!(server: server, name: "#ruby", joined: true)

    get servers_path
    assert_response :ok
    assert_match "DMs", response.body
    assert_match "alice", response.body
  end

  test "sidebar shows empty DMs section when no conversations" do
    server = create_server
    Channel.create!(server: server, name: "#ruby", joined: true)

    get servers_path
    assert_response :ok
    assert_select ".dm-list" do
      assert_select ".dm-item", count: 0
    end
  end

  test "DMs appear above channels in sidebar" do
    server = create_server
    Conversation.create!(server: server, target_nick: "alice")
    Channel.create!(server: server, name: "#ruby", joined: true)

    get servers_path
    assert_response :ok

    dm_pos = response.body.index("alice")
    channel_pos = response.body.index("#ruby")
    assert dm_pos < channel_pos, "DMs should appear before channels"
  end

  test "DMs sorted by recent activity" do
    server = create_server
    Conversation.create!(server: server, target_nick: "bob", last_message_at: 2.hours.ago)
    Conversation.create!(server: server, target_nick: "alice", last_message_at: 1.hour.ago)

    get servers_path
    assert_response :ok

    alice_pos = response.body.index("alice")
    bob_pos = response.body.index("bob")
    assert alice_pos < bob_pos, "More recent DM (alice) should appear first"
  end

  test "unread badge on DM" do
    server = create_server
    conversation = Conversation.create!(server: server, target_nick: "alice")

    msg1 = Message.create!(
      server: server,
      channel: nil,
      target: "alice",
      sender: "alice",
      content: "First",
      message_type: "privmsg"
    )
    conversation.update!(last_read_message_id: msg1.id)

    Message.create!(
      server: server,
      channel: nil,
      target: "alice",
      sender: "alice",
      content: "Unread",
      message_type: "privmsg"
    )

    get servers_path
    assert_response :ok
    assert_select ".dm-item.-unread"
    assert_select ".dm-item .badge", text: "1"
  end

  test "viewing PM conversation shows message history" do
    server = create_server
    conversation = Conversation.create!(server: server, target_nick: "alice")

    Message.create!(
      server: server,
      channel: nil,
      target: "alice",
      sender: "alice",
      content: "Message from alice",
      message_type: "privmsg"
    )

    Message.create!(
      server: server,
      channel: nil,
      target: "alice",
      sender: "testnick",
      content: "Reply to alice",
      message_type: "privmsg"
    )

    get conversation_path(conversation)
    assert_response :ok
    assert_match "Message from alice", response.body
    assert_match "Reply to alice", response.body
  end

  test "sending reply in PM conversation" do
    server = create_server
    conversation = Conversation.create!(server: server, target_nick: "alice")

    post conversation_messages_path(conversation), params: { content: "Hello alice!" }

    message = Message.last
    assert_equal "Hello alice!", message.content
    assert_equal "alice", message.target
    assert_equal "testnick", message.sender
  end

  test "/msg from channel then view conversation shows message" do
    server = create_server
    channel = Channel.create!(server: server, name: "#general", joined: true)

    post channel_messages_path(channel), params: { content: "/msg bob hey there" }

    conversation = Conversation.find_by!(server: server, target_nick: "bob")

    get conversation_path(conversation)
    assert_response :ok
    assert_match "hey there", response.body
  end
end
