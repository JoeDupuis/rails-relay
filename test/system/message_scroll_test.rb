require "application_system_test_case"

class MessageScrollTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)
    page.driver.browser.resize(width: 1200, height: 600)
  end

  def create_server_with_channel_and_many_messages
    server = @user.servers.create!(
      address: "#{@test_id}-irc.scroll.test",
      nickname: "testnick",
      connected_at: Time.current
    )
    channel = Channel.create!(server: server, name: "#scroll-test", joined: true, topic: "Test channel")
    ChannelUser.create!(channel: channel, nickname: "testnick", modes: "")

    50.times do |i|
      Message.create!(
        channel: channel,
        server: server,
        sender: "bot",
        message_type: "privmsg",
        content: "Message number #{i + 1} with some padding text",
        created_at: (50 - i).minutes.ago
      )
    end

    channel
  end

  def send_message_via_irc(server, channel, sender, content)
    IrcEventHandler.handle(server, {
      type: "message",
      data: {
        target: channel.name,
        source: "#{sender}!user@host.example.com",
        text: content
      }
    })
  end

  test "auto-scroll on new message when at bottom" do
    channel = create_server_with_channel_and_many_messages
    sign_in_as(@user)
    visit channel_path(channel)

    assert_selector ".message-item", minimum: 50

    send_message_via_irc(channel.server, channel, "alice", "Brand new message that just arrived")

    assert_selector ".message-item .content", text: "Brand new message that just arrived", wait: 5
  end

  test "no scroll when reading history" do
    channel = create_server_with_channel_and_many_messages
    sign_in_as(@user)
    visit channel_path(channel)

    assert_selector ".message-item", minimum: 50

    page.execute_script("document.querySelector('.messages').scrollTop = 0")
    sleep 0.2

    send_message_via_irc(channel.server, channel, "alice", "New message while reading history")

    assert_selector ".new-messages-indicator:not(.-hidden)", text: "New messages below", wait: 5

    scroll_position = page.evaluate_script("document.querySelector('.messages').scrollTop")
    assert_equal 0, scroll_position, "Should NOT have scrolled when user is reading history"
  end

  test "click indicator to scroll" do
    channel = create_server_with_channel_and_many_messages
    sign_in_as(@user)
    visit channel_path(channel)

    assert_selector ".message-item", minimum: 50

    page.execute_script("document.querySelector('.messages').scrollTop = 0")
    sleep 0.2

    send_message_via_irc(channel.server, channel, "alice", "This triggers the indicator")

    assert_selector ".new-messages-indicator:not(.-hidden)", text: "New messages below", wait: 5

    find(".new-messages-indicator").click

    assert_no_selector ".new-messages-indicator:not(.-hidden)", wait: 5

    scroll_position = page.evaluate_script("document.querySelector('.messages').scrollTop")
    scroll_height = page.evaluate_script("document.querySelector('.messages').scrollHeight")
    client_height = page.evaluate_script("document.querySelector('.messages').clientHeight")

    assert scroll_position >= scroll_height - client_height - 50, "Should have scrolled to bottom"
  end

  test "scroll on send" do
    channel = create_server_with_channel_and_many_messages
    sign_in_as(@user)
    visit channel_path(channel)

    assert_selector ".message-item", minimum: 50

    page.execute_script("document.querySelector('.messages').scrollTop = 0")
    sleep 0.2

    fill_in "content", with: "My sent message"
    click_button "Send"

    sleep 0.5

    scroll_position = page.evaluate_script("document.querySelector('.messages').scrollTop")
    scroll_height = page.evaluate_script("document.querySelector('.messages').scrollHeight")
    client_height = page.evaluate_script("document.querySelector('.messages').clientHeight")

    assert scroll_position >= scroll_height - client_height - 50, "Should have scrolled to bottom after sending"
  end
end
