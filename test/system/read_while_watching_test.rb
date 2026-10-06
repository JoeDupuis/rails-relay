require "application_system_test_case"

class ReadWhileWatchingTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)
    @server = @user.servers.create!(address: "#{@test_id}-watch.example.chat", nickname: "testnick", connected_at: Time.current)
    @channel = Channel.create!(server: @server, name: "#watch-#{@test_id}", joined: true)
    initial = Message.create!(server: @server, channel: @channel, sender: "system", content: "Initial message", message_type: "notice")
    @channel.update!(last_read_message_id: initial.id)
    Current.user_id = @user.id
  end

  teardown do
    Current.user_id = nil
  end

  test "messages arriving in the open channel are read while the window is focused" do
    sign_in_as(@user)
    visit channel_path(@channel)
    assert_selector ".channel-item", text: @channel.name

    receive_message("Hello while watching")

    assert_selector ".message-item", text: "Hello while watching", wait: 5
    within(".channel-item", text: @channel.name) do
      assert_no_selector ".badge", wait: 5
    end
    assert_eventually { @channel.reload.unread_count.zero? }
  end

  test "messages accumulate while the window is unfocused and clear on refocus" do
    sign_in_as(@user)
    visit channel_path(@channel)
    assert_selector ".channel-item", text: @channel.name

    page.execute_script("document.hasFocus = () => false")
    receive_message("Hello while away")

    assert_selector ".message-item", text: "Hello while away", wait: 5
    within(".channel-item", text: @channel.name) do
      assert_selector ".badge", text: "1", wait: 5
    end

    page.execute_script("document.hasFocus = () => true; window.dispatchEvent(new Event('focus'))")

    within(".channel-item", text: @channel.name) do
      assert_no_selector ".badge", wait: 5
    end
    assert_eventually { @channel.reload.unread_count.zero? }
  end

  test "new messages line marks where unread messages start when opening a channel" do
    Message.create!(server: @server, channel: @channel, sender: "alice", content: "Missed message", message_type: "privmsg")

    sign_in_as(@user)
    visit channel_path(@channel)

    assert_selector ".unread-divider + .message-item", text: "Missed message"
    assert_selector ".unread-divider", count: 1
  end

  test "no new messages line when the channel is already read" do
    sign_in_as(@user)
    visit channel_path(@channel)
    assert_selector ".message-item", text: "Initial message"

    receive_message("Hello while watching")

    assert_selector ".message-item", text: "Hello while watching", wait: 5
    assert_no_selector ".unread-divider"
  end

  test "new messages line stays after refocusing the window" do
    sign_in_as(@user)
    visit channel_path(@channel)
    assert_selector ".message-item", text: "Initial message"

    page.execute_script("document.hasFocus = () => false")
    receive_message("First while away")
    assert_selector ".message-item", text: "First while away", wait: 5
    receive_message("Second while away")
    assert_selector ".message-item", text: "Second while away", wait: 5

    page.execute_script("document.hasFocus = () => true; window.dispatchEvent(new Event('focus'))")
    within(".channel-item", text: @channel.name) do
      assert_no_selector ".badge", wait: 5
    end

    assert_selector ".unread-divider", count: 1
    assert_selector ".unread-divider + .message-item", text: "First while away"
  end

  test "direct messages arriving in the open conversation are read while the window is focused" do
    conversation = Conversation.create!(server: @server, target_nick: "alice")
    first = Message.create!(server: @server, target: "alice", sender: "alice", content: "Earlier", message_type: "privmsg")
    conversation.update!(last_read_message_id: first.id)

    sign_in_as(@user)
    visit conversation_path(conversation)
    assert_selector ".dm-item", text: "alice"

    IrcEventHandler.handle(@server, {
      type: "message",
      data: { target: @server.nickname, source: "alice!user@host.example.com", text: "Hi there" }
    })

    assert_selector ".message-item", text: "Hi there", wait: 5
    within(".dm-item", text: "alice") do
      assert_no_selector ".badge", wait: 5
    end
    assert_eventually { conversation.reload.unread_count.zero? }
  end

  private

  def assert_eventually(wait: 5)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + wait
    sleep 0.1 until yield || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
    assert yield
  end

  def receive_message(text)
    IrcEventHandler.handle(@server, {
      type: "message",
      data: { target: @channel.name, source: "alice!user@host.example.com", text: text }
    })
  end
end
