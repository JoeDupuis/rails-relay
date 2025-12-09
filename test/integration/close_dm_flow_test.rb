require "test_helper"
require "webmock/minitest"

class CloseDmFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    @test_id = SecureRandom.hex(4)

    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_return(status: 202, body: "", headers: {})

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

  test "closing DM broadcasts sidebar remove" do
    server = create_server
    conversation = Conversation.create!(server: server, target_nick: "alice")

    assert_turbo_stream_broadcasts "sidebar_#{@user.id}" do
      conversation.close!
      conversation.broadcast_sidebar_remove
    end
  end

  test "reopening DM broadcasts sidebar add" do
    server = create_server
    conversation = Conversation.create!(server: server, target_nick: "alice", closed_at: Time.current)

    assert_turbo_stream_broadcasts "sidebar_#{@user.id}" do
      conversation.reopen!
      conversation.broadcast_sidebar_add
    end
  end

  test "new message reopens closed conversation" do
    server = create_server
    conversation = Conversation.create!(server: server, target_nick: "alice", closed_at: Time.current)

    assert conversation.closed?
    assert_includes Conversation.closed.to_a, conversation

    post internal_irc_events_path, params: {
      server_id: server.id,
      user_id: @user.id,
      event: {
        type: "message",
        data: {
          source: "alice!user@host",
          target: "testnick",
          text: "Hey there!"
        }
      }
    }, headers: {
      "Authorization" => "Bearer #{ENV['INTERNAL_API_SECRET']}"
    }

    assert_not conversation.reload.closed?
    assert_includes Conversation.open.to_a, conversation
  end

  test "sidebar only shows open conversations" do
    server = create_server
    open_convo = Conversation.create!(server: server, target_nick: "alice")
    closed_convo = Conversation.create!(server: server, target_nick: "bob", closed_at: Time.current)

    get servers_path
    assert_response :ok
    assert_match "alice", response.body
    assert_no_match "bob", response.body
  end

  test "clicking username reopens closed conversation and redirects" do
    server = create_server
    closed_convo = Conversation.create!(server: server, target_nick: "bob", closed_at: Time.current)

    post server_conversations_path(server), params: { target_nick: "bob" }

    assert_not closed_convo.reload.closed?
    assert_redirected_to conversation_path(closed_convo)
  end
end
