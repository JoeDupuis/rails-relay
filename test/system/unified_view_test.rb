require "application_system_test_case"

class UnifiedViewTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)

    stub_request(:get, %r{#{Rails.configuration.irc_service_url}/internal/irc/ison})
      .to_return(status: 200, body: { online: [ "alice" ] }.to_json, headers: { "Content-Type" => "application/json" })

    stub_request(:post, %r{#{Rails.configuration.irc_service_url}/internal/irc/commands})
      .to_return(status: 202, body: "", headers: {})
  end

  def create_server_with_channel
    server = @user.servers.create!(
      address: "#{@test_id}-irc.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    channel = Channel.create!(server: server, name: "#ruby", joined: true, topic: "Ruby discussion", auto_join: true)
    ChannelUser.create!(channel: channel, nickname: "alice", modes: "o")
    ChannelUser.create!(channel: channel, nickname: "bob", modes: "")
    Message.create!(channel: channel, server: server, sender: "alice", message_type: "privmsg", content: "Hello")
    [ server, channel ]
  end

  def create_server_with_conversation
    server = @user.servers.create!(
      address: "#{@test_id}-irc.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    conversation = Conversation.create!(server: server, target_nick: "alice", online: true)
    Message.create!(server: server, channel: nil, target: "alice", sender: "alice", message_type: "privmsg", content: "Hello")
    [ server, conversation ]
  end

  test "DM view renders correctly" do
    server, conversation = create_server_with_conversation
    sign_in_as(@user)

    visit conversation_path(conversation)
    assert_selector ".channel-view"

    assert_selector ".header .name", text: "alice"
    assert_selector ".header .topic", text: "Direct Message"
    assert_selector ".message-input .field"
    assert_no_selector ".userlist-toggle"
    assert_no_selector ".auto-join-form"
    assert_no_selector "input[value='Leave']"
  end

  test "channel view still works" do
    server, channel = create_server_with_channel
    sign_in_as(@user)

    visit channel_path(channel)
    assert_selector ".channel-view"

    assert_selector ".header .name", text: "#ruby"
    assert_selector ".header .topic", text: "Ruby discussion"
    assert_selector ".message-input .field"
    assert_selector ".userlist-toggle", visible: :all
    assert_selector ".auto-join-form"
    assert_selector "button", text: "Leave"
  end

  test "DM message sending still works" do
    server, conversation = create_server_with_conversation

    stub_request(:post, "http://localhost:3001/irc/commands")
      .to_return(status: 200, body: "")

    sign_in_as(@user)

    visit conversation_path(conversation)
    assert_selector ".message-input .field"

    fill_in "content", with: "Hello from test"
    click_button "Send"

    assert_selector ".message-item .content", text: "Hello from test"
  end
end
