require "test_helper"

class ConversationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
    sign_in_as(@user)
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

    sign_out
    other_user = users(:jane)
    sign_in_as(other_user)

    get conversation_path(conversation)
    assert_response :not_found
  end

  test "POST /servers/:server_id/conversations creates conversation" do
    server = create_server

    assert_difference -> { Conversation.count } do
      post server_conversations_path(server), params: { target_nick: "bob" }
    end

    conversation = Conversation.last
    assert_equal server, conversation.server
    assert_equal "bob", conversation.target_nick
  end

  test "POST /servers/:server_id/conversations redirects to conversation show page" do
    server = create_server

    post server_conversations_path(server), params: { target_nick: "bob" }

    conversation = Conversation.last
    assert_redirected_to conversation_path(conversation)
  end

  test "POST /servers/:server_id/conversations finds existing conversation" do
    server = create_server
    existing = create_conversation(server, target_nick: "bob")

    assert_no_difference -> { Conversation.count } do
      post server_conversations_path(server), params: { target_nick: "bob" }
    end

    assert_redirected_to conversation_path(existing)
  end

  test "user can only create conversations on their own servers" do
    server = create_server

    sign_out
    other_user = users(:jane)
    sign_in_as(other_user)

    post server_conversations_path(server), params: { target_nick: "bob" }
    assert_response :not_found
  end

  test "POST /servers/:server_id/conversations reopens closed conversation" do
    server = create_server
    closed_conversation = Conversation.create!(
      server: server,
      target_nick: "bob",
      closed_at: Time.current
    )

    assert closed_conversation.closed?

    assert_no_difference -> { Conversation.count } do
      post server_conversations_path(server), params: { target_nick: "bob" }
    end

    assert_not closed_conversation.reload.closed?
    assert_redirected_to conversation_path(closed_conversation)
  end

  test "conversation show with offline user shows disabled input" do
    server = create_server
    conversation = create_conversation(server, target_nick: "alice")
    conversation.update!(online: false)

    get conversation_path(conversation)
    assert_response :ok
    assert_match "alice is offline.", response.body
    assert_no_match /<input[^>]*type="text"[^>]*name="content"/, response.body
  end

  test "conversation show with online user shows enabled input" do
    server = create_server
    conversation = create_conversation(server, target_nick: "alice")
    conversation.update!(online: true)

    get conversation_path(conversation)
    assert_response :ok
    assert_no_match "alice is offline.", response.body
    assert_match /<input[^>]*type="text"[^>]*name="content"/, response.body
  end
end
