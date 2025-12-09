require "application_system_test_case"

class DmInitiationTest < ApplicationSystemTestCase
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

  def create_server_with_channel
    server = @user.servers.create!(
      address: "#{@test_id}-irc.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    channel = Channel.create!(server: server, name: "#test", joined: true)
    ChannelUser.create!(channel: channel, nickname: "alice", modes: "")
    ChannelUser.create!(channel: channel, nickname: "bob", modes: "o")
    Message.create!(channel: channel, server: server, sender: "alice", message_type: "privmsg", content: "Hello everyone")
    [ server, channel ]
  end

  test "click username in user list opens DM" do
    server, channel = create_server_with_channel
    sign_in_user

    visit channel_path(channel)
    assert_selector ".user-list"

    within ".user-list" do
      click_link "alice"
    end

    assert_current_path %r{/conversations/\d+}
    assert_selector ".channel-view .header .name", text: "alice"
    assert_selector ".header .topic", text: "Direct Message"
  end

  test "click username in user list creates conversation in sidebar" do
    server, channel = create_server_with_channel
    sign_in_user

    visit channel_path(channel)
    assert_no_selector ".channel-sidebar .dm-item", text: "alice"

    within ".user-list" do
      click_link "alice"
    end

    assert_selector ".channel-sidebar .dm-item", text: "alice"
  end

  test "click username in message opens DM" do
    server, channel = create_server_with_channel
    sign_in_user

    visit channel_path(channel)
    assert_selector ".message-item"

    within first(".message-item.-privmsg") do
      click_link "alice"
    end

    assert_current_path %r{/conversations/\d+}
    assert_selector ".channel-view .header .name", text: "alice"
    assert_selector ".header .topic", text: "Direct Message"
  end
end
