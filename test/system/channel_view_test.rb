require "application_system_test_case"

class ChannelViewTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)
  end

  def sign_in_user
    visit new_session_path
    fill_in "email_address", with: @user.email_address
    fill_in "password", with: "password123"
    click_button "Sign in"
    assert_selector ".app-layout"
  end

  def create_server_with_channel_and_messages
    server = @user.servers.create!(
      address: "#{@test_id}-irc.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    channel = Channel.create!(server: server, name: "#test", joined: true, topic: "Welcome to the test channel")

    ChannelUser.create!(channel: channel, nickname: "alice", modes: "o")
    ChannelUser.create!(channel: channel, nickname: "bob", modes: "v")
    ChannelUser.create!(channel: channel, nickname: "charlie")
    ChannelUser.create!(channel: channel, nickname: "dave")

    Message.create!(channel: channel, server: server, sender: "alice", message_type: "privmsg", content: "Hello everyone", created_at: 1.hour.ago)
    Message.create!(channel: channel, server: server, sender: "bob", message_type: "privmsg", content: "Hey alice!", created_at: 50.minutes.ago)
    Message.create!(channel: channel, server: server, sender: "charlie", message_type: "action", content: "waves", created_at: 40.minutes.ago)
    Message.create!(channel: channel, server: server, sender: "joe", message_type: "join", content: "", created_at: 30.minutes.ago)
    Message.create!(channel: channel, server: server, sender: "alice", message_type: "privmsg", content: "How's everyone doing?", created_at: 20.minutes.ago)

    channel
  end

  test "shows channel name and topic" do
    channel = create_server_with_channel_and_messages
    sign_in_user

    visit channel_path(channel)
    assert_selector ".channel-view"

    assert_selector ".channel-view .header .name", text: "#test"
    assert_selector ".channel-view .header .topic", text: "Welcome to the test channel"
  end

  test "shows message list" do
    channel = create_server_with_channel_and_messages
    sign_in_user

    visit channel_path(channel)
    assert_selector ".channel-view"

    assert_selector ".message-item", count: 5
    assert_selector ".message-item .content", text: "Hello everyone"
    assert_selector ".message-item .content", text: "Hey alice!"
  end

  test "message types styled differently" do
    channel = create_server_with_channel_and_messages
    sign_in_user

    visit channel_path(channel)
    assert_selector ".channel-view"

    assert_selector ".message-item.-privmsg", text: "Hello everyone"
    assert_selector ".message-item.-action", text: "waves"
    assert_selector ".message-item.-join"
  end

  test "shows users grouped by mode" do
    channel = create_server_with_channel_and_messages
    sign_in_user

    visit channel_path(channel)
    assert_selector ".userlist"

    within ".userlist" do
      assert_selector ".user-list .header", text: "4 users"
      assert_selector ".user-item.-op .nick", text: "alice"
      assert_selector ".user-item.-voice .nick", text: "bob"
      assert_selector ".user-item .nick", text: "charlie"
    end
  end

  test "shows message input when connected" do
    channel = create_server_with_channel_and_messages
    sign_in_user

    visit channel_path(channel)
    assert_selector ".channel-view"

    assert_selector ".message-input .field"
    assert_selector ".message-input input[value='Send']"
  end

  test "shows disabled message when not connected" do
    server = @user.servers.create!(
      address: "#{@test_id}-disconnected.example.chat",
      nickname: "testnick",
      connected_at: nil
    )
    channel = Channel.create!(server: server, name: "#offline", joined: true)
    sign_in_user

    visit channel_path(channel)
    assert_selector ".channel-view"

    assert_selector ".message-input .disabled", text: "Connect to server to send messages."
    assert_no_selector ".message-input .field"
  end

  test "own messages highlighted" do
    server = @user.servers.create!(
      address: "#{@test_id}-irc.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    channel = Channel.create!(server: server, name: "#test", joined: true)
    Message.create!(channel: channel, server: server, sender: "alice", message_type: "privmsg", content: "Hello")
    Message.create!(channel: channel, server: server, sender: "testnick", message_type: "privmsg", content: "Hi there!")
    sign_in_user

    visit channel_path(channel)
    assert_selector ".channel-view"

    assert_selector ".message-item.-mine .sender", text: "testnick"
    assert_no_selector ".message-item.-mine .sender", text: "alice"
  end

  test "channel input disabled when not joined" do
    server = @user.servers.create!(
      address: "#{@test_id}-connected.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    channel = Channel.create!(server: server, name: "#notjoined", joined: false)
    sign_in_user

    visit channel_path(channel)
    assert_selector ".channel-view"

    assert_selector ".message-input .field[disabled]"
    assert_selector ".not-joined-banner", text: "not in this channel"
    assert_selector "form input[value='Join']"
    assert_no_selector "form input[value='Leave']"
  end
end
