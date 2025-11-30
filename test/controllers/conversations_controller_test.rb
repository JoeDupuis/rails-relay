require "test_helper"

class ConversationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    @test_id = SecureRandom.hex(4)
  end

  def unique_address(base = "irc.example")
    "#{base}-#{@test_id}.chat"
  end

  def create_server(address: nil)
    address ||= unique_address
    @user.servers.create!(address: address, nickname: "testnick", connected_at: Time.current)
  end

  def create_conversation(server, target_nick: "alice")
    Conversation.create!(server: server, target_nick: target_nick)
  end

  test "GET /conversations/:id returns 200" do
    server = create_server
    conversation = create_conversation(server)

    get conversation_path(conversation)
    assert_response :ok
  end

  test "GET /conversations/:id shows target nick" do
    server = create_server
    conversation = create_conversation(server, target_nick: "alice")

    get conversation_path(conversation)
    assert_response :ok
    assert_match "alice", response.body
  end

  test "GET /conversations/:id shows messages" do
    server = create_server
    conversation = create_conversation(server, target_nick: "alice")

    Message.create!(
      server: server,
      channel: nil,
      target: "alice",
      sender: "alice",
      content: "Hello from alice",
      message_type: "privmsg"
    )

    get conversation_path(conversation)
    assert_response :ok
    assert_match "Hello from alice", response.body
  end

  test "GET /conversations/:id marks as read" do
    server = create_server
    conversation = create_conversation(server, target_nick: "alice")

    msg = Message.create!(
      server: server,
      channel: nil,
      target: "alice",
      sender: "alice",
      content: "Hello",
      message_type: "privmsg"
    )

    assert_nil conversation.last_read_message_id
    get conversation_path(conversation)

    assert_equal msg.id, conversation.reload.last_read_message_id
  end

  test "user can only view their own conversations" do
    server = create_server
    conversation = create_conversation(server)

    delete session_path
    other_user = users(:jane)
    post session_path, params: { email_address: other_user.email_address, password: "secret456" }

    get conversation_path(conversation)
    assert_response :not_found
  end
end
