require "test_helper"
require "webmock/minitest"

class Conversation::MessagesControllerTest < ActionDispatch::IntegrationTest
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

  def create_conversation(server, target_nick: "alice")
    Conversation.create!(server: server, target_nick: target_nick)
  end

  test "POST /conversations/:conversation_id/messages creates message" do
    server = create_server
    conversation = create_conversation(server, target_nick: "alice")

    assert_difference -> { Message.count } do
      post conversation_messages_path(conversation), params: { content: "Hello alice" }
    end

    message = Message.last
    assert_equal "Hello alice", message.content
    assert_equal "alice", message.target
    assert_equal "testnick", message.sender
    assert_nil message.channel
  end

  test "POST /conversations/:conversation_id/messages sends IRC command" do
    server = create_server
    conversation = create_conversation(server, target_nick: "alice")

    post conversation_messages_path(conversation), params: { content: "Hello alice" }

    assert_requested(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands") do |req|
      body = JSON.parse(req.body)
      body["command"] == "privmsg" &&
        body["params"]["target"] == "alice" &&
        body["params"]["message"] == "Hello alice"
    end
  end

  test "POST /conversations/:conversation_id/messages updates last_message_at" do
    server = create_server
    conversation = create_conversation(server, target_nick: "alice")

    assert_nil conversation.last_message_at

    freeze_time do
      post conversation_messages_path(conversation), params: { content: "Hello" }
      assert_equal Time.current, conversation.reload.last_message_at
    end
  end

  test "POST /conversations/:conversation_id/messages returns success for turbo stream" do
    server = create_server
    conversation = create_conversation(server, target_nick: "alice")

    post conversation_messages_path(conversation),
      params: { content: "Hello" },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
  end

  test "POST /conversations/:conversation_id/messages returns success on HTML request" do
    server = create_server
    conversation = create_conversation(server, target_nick: "alice")

    post conversation_messages_path(conversation), params: { content: "Hello" }

    assert_response :success
  end

  test "POST /conversations/:conversation_id/messages redirects with alert when service unavailable" do
    server = create_server
    conversation = create_conversation(server, target_nick: "alice")

    WebMock.reset!
    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_raise(Errno::ECONNREFUSED)

    post conversation_messages_path(conversation), params: { content: "Hello" }

    assert_redirected_to conversation_path(conversation)
    follow_redirect!
    assert_match "IRC service unavailable", response.body
  end

  test "POST /conversations/:conversation_id/messages redirects with alert when connection not found" do
    server = create_server
    conversation = create_conversation(server, target_nick: "alice")

    WebMock.reset!
    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_return(status: 404, body: "", headers: {})

    post conversation_messages_path(conversation), params: { content: "Hello" }

    assert_redirected_to conversation_path(conversation)
    follow_redirect!
    assert_match "not connected", response.body
  end

  test "POST with multi-line content creates multiple messages" do
    server = create_server
    conversation = create_conversation(server, target_nick: "alice")

    assert_difference -> { Message.count }, 3 do
      post conversation_messages_path(conversation), params: { content: "line one\nline two\nline three" }
    end

    messages = Message.last(3)
    assert_equal [ "line one", "line two", "line three" ], messages.map(&:content)
  end

  test "POST with multi-line content filters blank lines" do
    server = create_server
    conversation = create_conversation(server, target_nick: "alice")

    assert_difference -> { Message.count }, 2 do
      post conversation_messages_path(conversation), params: { content: "hello\n\n  \nworld" }
    end

    messages = Message.last(2)
    assert_equal %w[hello world], messages.map(&:content)
  end

  test "POST with multi-line content sends separate IRC commands per line" do
    server = create_server
    conversation = create_conversation(server, target_nick: "alice")

    post conversation_messages_path(conversation), params: { content: "first\nsecond" }

    assert_requested(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands", times: 2)
  end

  test "user can only send to their own conversations" do
    server = create_server
    conversation = create_conversation(server)

    sign_out
    other_user = users(:jane)
    sign_in_as(other_user)

    post conversation_messages_path(conversation), params: { content: "Hello" }
    assert_response :not_found
  end
end
