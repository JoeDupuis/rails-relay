require "test_helper"

class Conversation::ReadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
    sign_in_as(@user)
    @test_id = SecureRandom.hex(4)
    @server = @user.servers.create!(address: "irc-#{@test_id}.example.chat", nickname: "testnick", connected_at: Time.current)
    @conversation = Conversation.create!(server: @server, target_nick: "alice")
  end

  test "POST /conversations/:conversation_id/read marks the conversation as read" do
    first = Message.create!(server: @server, target: "alice", sender: "alice", content: "one", message_type: "privmsg")
    @conversation.update!(last_read_message_id: first.id)
    latest = Message.create!(server: @server, target: "alice", sender: "alice", content: "two", message_type: "privmsg")

    post conversation_read_path(@conversation)

    assert_response :no_content
    assert_equal latest.id, @conversation.reload.last_read_message_id
    assert_equal 0, @conversation.unread_count
  end

  test "POST /conversations/:conversation_id/read cannot mark another user's conversation" do
    other_server = users(:jane).servers.create!(address: "other-#{@test_id}.example.chat", nickname: "jane")
    other_conversation = Conversation.create!(server: other_server, target_nick: "bob")

    post conversation_read_path(other_conversation)

    assert_response :not_found
  end
end
