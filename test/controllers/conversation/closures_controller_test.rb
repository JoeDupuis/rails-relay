require "test_helper"

class Conversation::ClosuresControllerTest < ActionDispatch::IntegrationTest
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

  test "POST /conversations/:conversation_id/closure closes conversation" do
    server = create_server
    conversation = create_conversation(server)

    assert_not conversation.closed?

    post conversation_closure_path(conversation)

    assert conversation.reload.closed?
    assert_redirected_to server_path(server)
  end

  test "POST /conversations/:conversation_id/closure redirects to server page with notice" do
    server = create_server
    conversation = create_conversation(server)

    post conversation_closure_path(conversation)

    assert_redirected_to server_path(server)
    follow_redirect!
    assert_match "Conversation closed", response.body
  end

  test "POST /conversations/:conversation_id/closure for other user's conversation returns 404" do
    server = create_server
    conversation = create_conversation(server)

    delete session_path
    other_user = users(:jane)
    post session_path, params: { email_address: other_user.email_address, password: "secret456" }

    post conversation_closure_path(conversation)
    assert_response :not_found
  end
end
