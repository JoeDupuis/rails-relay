require "test_helper"
require "webmock/minitest"

class DmOfflineFeedbackTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper

  setup do
    @user = users(:joe)
    sign_in_as(@user)
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

  test "offline status change broadcasts input update" do
    server = create_server
    conversation = Conversation.create!(server: server, target_nick: "alice", online: true)

    stream = [ server, :dm, "alice" ]
    assert_turbo_stream_broadcasts stream do
      conversation.update!(online: false)
      conversation.broadcast_input_update
    end
  end

  test "online status change broadcasts input update" do
    server = create_server
    conversation = Conversation.create!(server: server, target_nick: "alice", online: false)

    stream = [ server, :dm, "alice" ]
    assert_turbo_stream_broadcasts stream do
      conversation.update!(online: true)
      conversation.broadcast_input_update
    end
  end

  test "broadcast_presence_update triggers input update" do
    server = create_server
    conversation = Conversation.create!(server: server, target_nick: "alice", online: true)

    stream = [ server, :dm, "alice" ]
    assert_turbo_stream_broadcasts stream do
      conversation.broadcast_presence_update
    end
  end

  test "ISON response updates input area via turbo stream" do
    server = create_server
    conversation = Conversation.create!(server: server, target_nick: "alice", online: true)

    stub_request(:get, %r{internal/irc/ison})
      .to_return(status: 200, body: { online: [] }.to_json, headers: { "Content-Type" => "application/json" })

    get ison_path, as: :turbo_stream

    assert_response :ok
    assert_includes response.body, "input_conversation_#{conversation.id}"
  end
end
