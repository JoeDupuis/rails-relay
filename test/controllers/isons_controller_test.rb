require "test_helper"

class IsonsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
    sign_in_as(@user)
    @test_id = SecureRandom.hex(4)
  end

  def unique_address(base = "irc.example")
    "#{base}-#{@test_id}.chat"
  end

  def create_server(connected: true)
    @user.servers.create!(
      address: unique_address,
      nickname: "testnick",
      connected_at: connected ? Time.current : nil
    )
  end

  test "GET /ison returns turbo stream" do
    server = create_server
    conversation = Conversation.create!(server: server, target_nick: "alice")

    InternalApiClient.stub :ison, [ "alice" ] do
      get ison_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :ok
    assert_match "turbo-stream", response.content_type
  end

  test "GET /ison updates online status for conversations" do
    server = create_server
    alice = Conversation.create!(server: server, target_nick: "alice", online: false)
    bob = Conversation.create!(server: server, target_nick: "bob", online: true)

    InternalApiClient.stub :ison, [ "alice" ] do
      get ison_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert alice.reload.online?
    assert_not bob.reload.online?
  end

  test "GET /ison handles case-insensitive nick matching" do
    server = create_server
    conversation = Conversation.create!(server: server, target_nick: "Alice", online: false)

    InternalApiClient.stub :ison, [ "alice" ] do
      get ison_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert conversation.reload.online?
  end

  test "GET /ison ignores closed conversations" do
    server = create_server
    open_convo = Conversation.create!(server: server, target_nick: "alice", online: false)
    closed_convo = Conversation.create!(server: server, target_nick: "bob", online: false, closed_at: Time.current)

    InternalApiClient.stub :ison, [ "alice", "bob" ] do
      get ison_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert open_convo.reload.online?
    assert_not closed_convo.reload.online?
  end

  test "GET /ison ignores disconnected servers" do
    connected_server = create_server(connected: true)
    disconnected_server = @user.servers.create!(
      address: "#{unique_address}-disconnected",
      nickname: "testnick",
      connected_at: nil
    )

    connected_convo = Conversation.create!(server: connected_server, target_nick: "alice", online: false)
    disconnected_convo = Conversation.create!(server: disconnected_server, target_nick: "bob", online: false)

    InternalApiClient.stub :ison, [ "alice", "bob" ] do
      get ison_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert connected_convo.reload.online?
    assert_not disconnected_convo.reload.online?
  end

  test "GET /ison handles nil response from IRC service" do
    server = create_server
    conversation = Conversation.create!(server: server, target_nick: "alice", online: true)

    InternalApiClient.stub :ison, nil do
      get ison_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :ok
    assert_not conversation.reload.online?
  end

  test "GET /ison requires authentication" do
    sign_out

    get ison_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_redirected_to new_session_path
  end

  test "GET /ison returns turbo stream replace actions" do
    server = create_server
    conversation = Conversation.create!(server: server, target_nick: "alice")

    InternalApiClient.stub :ison, [ "alice" ] do
      get ison_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_match "<turbo-stream", response.body
    assert_match "action=\"replace\"", response.body
    assert_match "conversation_#{conversation.id}_sidebar", response.body
  end
end
