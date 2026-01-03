require "application_system_test_case"
require "webmock/minitest"

class OwnMessageUnreadBadgeTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)

    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_return(status: 202, body: "", headers: {})
  end

  test "sending message to channel does not show unread badge for own message" do
    server = @user.servers.create!(
      address: "#{@test_id}-irc.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    channel = Channel.create!(server: server, name: "#test-#{@test_id}", joined: true)
    other_channel = Channel.create!(server: server, name: "#other-#{@test_id}", joined: true)

    initial_message = Message.create!(
      server: server,
      channel: channel,
      sender: "system",
      content: "Initial message",
      message_type: "notice"
    )
    channel.update!(last_read_message_id: initial_message.id)

    other_initial = Message.create!(
      server: server,
      channel: other_channel,
      sender: "system",
      content: "Initial message",
      message_type: "notice"
    )
    other_channel.update!(last_read_message_id: other_initial.id)

    sign_in_as(@user)
    visit channel_path(channel)

    within(".channel-item", text: "#test-#{@test_id}") do
      assert_no_selector ".badge"
    end

    within(".channel-item", text: "#other-#{@test_id}") do
      assert_no_selector ".badge"
    end

    fill_in "content", with: "Hello from me"
    click_button "Send"

    assert_selector ".message-item", text: "Hello from me", wait: 5

    channel.reload
    assert_equal channel.messages.maximum(:id), channel.last_read_message_id, "Channel should be marked as read after sending"

    within(".channel-item", text: "#test-#{@test_id}") do
      assert_no_selector ".badge", wait: 3
    end
  end
end
