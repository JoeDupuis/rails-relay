require "test_helper"

class AuthSweepTest < ActionDispatch::IntegrationTest
  test "GET / requires authentication" do
    get root_path
    assert_redirected_to new_session_path
  end

  test "GET /servers requires authentication" do
    get servers_path
    assert_redirected_to new_session_path
  end

  test "GET /channels/:id requires authentication" do
    user = users(:joe)
    server = user.servers.create!(address: "auth-sweep.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#test", joined: true)

    get channel_path(channel)
    assert_redirected_to new_session_path
  end

  test "GET /channels/:id/messages requires authentication" do
    get channel_messages_path(1, before_id: 1)
    assert_redirected_to new_session_path
  end

  test "GET /conversations/:id requires authentication" do
    user = users(:joe)
    server = user.servers.create!(address: "auth-sweep-conv.example.com", nickname: "testnick")
    conversation = Conversation.create!(server: server, target_nick: "alice")

    get conversation_path(conversation)
    assert_redirected_to new_session_path
  end

  test "GET /conversations/:id/messages requires authentication" do
    get conversation_messages_path(1, before_id: 1)
    assert_redirected_to new_session_path
  end

  test "GET /notifications requires authentication" do
    get notifications_path
    assert_redirected_to new_session_path
  end

  test "GET /ison requires authentication" do
    get ison_path
    assert_redirected_to new_session_path
  end
end
