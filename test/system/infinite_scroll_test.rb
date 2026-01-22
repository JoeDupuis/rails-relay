require "application_system_test_case"

class InfiniteScrollTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)
    page.driver.browser.resize(width: 1200, height: 600)
  end

  def create_server_with_channel_and_many_messages(count)
    server = @user.servers.create!(
      address: "#{@test_id}-irc.scroll.test",
      nickname: "testnick",
      connected_at: Time.current
    )
    channel = Channel.create!(server: server, name: "#infinite-scroll-test", joined: true, topic: "Test channel")
    ChannelUser.create!(channel: channel, nickname: "testnick", modes: "")

    count.times do |i|
      Message.create!(
        channel: channel,
        server: server,
        sender: "bot",
        message_type: "privmsg",
        content: "Message number #{i + 1} with some padding text to make it longer",
        created_at: (count - i).minutes.ago
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

  test "initial load is limited to 50 messages" do
    channel = create_server_with_channel_and_many_messages(100)
    sign_in_as(@user)
    visit channel_path(channel)

    assert_selector ".message-item", count: 50

    assert_selector ".message-item .content", text: "Message number 100"
    assert_no_selector ".message-item .content", text: /\AMessage number 1 /
  end

  test "scroll up loads more messages" do
    channel = create_server_with_channel_and_many_messages(100)
    sign_in_as(@user)
    visit channel_path(channel)

    assert_selector ".message-item", count: 50

    page.execute_script("document.querySelector('.messages').scrollTop = 0")

    assert_selector ".message-item", minimum: 51, wait: 5
  end

  test "scroll position preserved after loading more" do
    channel = create_server_with_channel_and_many_messages(100)
    sign_in_as(@user)
    visit channel_path(channel)

    assert_selector ".message-item", count: 50

    first_visible_content = page.evaluate_script("document.querySelector('#messages').children[0].querySelector('.content').textContent")

    page.execute_script("document.querySelector('.messages').scrollTop = 0")

    assert_selector ".message-item", minimum: 51, wait: 5

    still_has_original_first = page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll('.message-item .content'))
        .some(el => el.textContent.includes('#{first_visible_content.gsub("'", "\\\\'")}'))
    JS
    assert still_has_original_first, "Original first visible message should still be in the DOM"
  end

  test "no more messages state when all loaded" do
    channel = create_server_with_channel_and_many_messages(30)
    sign_in_as(@user)
    visit channel_path(channel)

    assert_selector ".message-item", count: 30

    page.execute_script("document.querySelector('.messages').scrollTop = 0")
    sleep 0.5

    assert_selector ".message-item", count: 30
  end

  test "new messages still append correctly while browsing history" do
    channel = create_server_with_channel_and_many_messages(100)
    sign_in_as(@user)
    visit channel_path(channel)

    assert_selector ".message-item", count: 50

    page.execute_script("document.querySelector('.messages').scrollTop = 0")

    assert_selector ".message-item", minimum: 51, wait: 5

    send_message_via_irc(channel.server, channel, "alice", "Brand new real-time message")

    assert_selector ".message-item .content", text: "Brand new real-time message", wait: 5

    assert_selector ".new-messages-indicator:not(.-hidden)", text: "New messages below"
  end

  test "loading indicator exists" do
    channel = create_server_with_channel_and_many_messages(100)
    sign_in_as(@user)
    visit channel_path(channel)

    assert_selector ".message-item", count: 50
    assert_selector ".loading-indicator", visible: :all
  end
end
