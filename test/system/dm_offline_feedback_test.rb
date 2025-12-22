require "application_system_test_case"

class DmOfflineFeedbackSystemTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)

    stub_request(:get, %r{#{Rails.configuration.irc_service_url}/internal/irc/ison})
      .to_return(status: 200, body: { online: [] }.to_json, headers: { "Content-Type" => "application/json" })

    stub_request(:post, %r{#{Rails.configuration.irc_service_url}/internal/irc/commands})
      .to_return(status: 202, body: "", headers: {})
  end

  def unique_address(base = "irc.example")
    "#{base}-#{@test_id}.chat"
  end

  def create_server(address: nil)
    address ||= unique_address
    @user.servers.create!(address: address, nickname: "testnick", connected_at: Time.current)
  end

  test "DM with offline user shows disabled input" do
    server = create_server
    conversation = Conversation.create!(server: server, target_nick: "alice", online: false)

    sign_in_as(@user)
    visit conversation_path(conversation)

    within(".input") do
      assert_selector ".message-input .disabled", text: "alice is offline."
      assert_no_selector "input[name='content']"
    end
  end

  test "DM with online user shows enabled input" do
    WebMock.reset!
    stub_request(:get, %r{#{Rails.configuration.irc_service_url}/internal/irc/ison})
      .to_return(status: 200, body: { online: [ "alice" ] }.to_json, headers: { "Content-Type" => "application/json" })
    stub_request(:post, %r{#{Rails.configuration.irc_service_url}/internal/irc/commands})
      .to_return(status: 202, body: "", headers: {})

    server = create_server
    conversation = Conversation.create!(server: server, target_nick: "alice", online: true)

    sign_in_as(@user)
    visit conversation_path(conversation)

    within(".input") do
      assert_no_text "alice is offline."
      assert_selector "input[name='content']"
    end
  end

  test "can still view messages with offline user" do
    server = create_server
    conversation = Conversation.create!(server: server, target_nick: "alice", online: false)

    Message.create!(
      server: server,
      channel: nil,
      target: "alice",
      sender: "alice",
      content: "Hello from alice",
      message_type: "privmsg"
    )

    sign_in_as(@user)
    visit conversation_path(conversation)

    assert_selector ".message-item", text: "Hello from alice"
    within(".input") do
      assert_selector ".message-input .disabled", text: "alice is offline."
    end
  end

  test "DM input enables when user comes online via ISON" do
    server = create_server
    conversation = Conversation.create!(server: server, target_nick: "alice", online: false)

    sign_in_as(@user)
    visit conversation_path(conversation)

    within(".input") do
      assert_selector ".message-input .disabled", text: "alice is offline."
    end

    conversation.update!(online: true)
    conversation.broadcast_input_update

    within(".input") do
      assert_no_text "alice is offline."
      assert_selector "input[name='content']", wait: 5
    end
  end

  test "DM input disables when user goes offline via ISON" do
    WebMock.reset!
    stub_request(:get, %r{#{Rails.configuration.irc_service_url}/internal/irc/ison})
      .to_return(status: 200, body: { online: [ "alice" ] }.to_json, headers: { "Content-Type" => "application/json" })
    stub_request(:post, %r{#{Rails.configuration.irc_service_url}/internal/irc/commands})
      .to_return(status: 202, body: "", headers: {})

    server = create_server
    conversation = Conversation.create!(server: server, target_nick: "alice", online: true)

    sign_in_as(@user)
    visit conversation_path(conversation)

    within(".input") do
      assert_selector "input[name='content']"
    end

    conversation.update!(online: false)
    conversation.broadcast_input_update

    within(".input") do
      assert_selector ".message-input .disabled", text: "alice is offline.", wait: 5
    end
  end
end
