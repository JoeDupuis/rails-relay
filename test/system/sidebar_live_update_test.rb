require "application_system_test_case"

class SidebarLiveUpdateTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)
  end

  def sign_in_user
    visit new_session_path
    fill_in "email_address", with: @user.email_address
    fill_in "password", with: "password123"
    click_button "Sign in"
    assert_no_selector "input[id='password']", wait: 5
  end

  test "new DM conversation appears in sidebar" do
    server = @user.servers.create!(
      address: "#{@test_id}-dm.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )

    sign_in_user
    visit server_path(server)

    assert_no_selector ".dm-item", text: "alice"

    IrcEventHandler.handle(server, {
      type: "message",
      data: {
        target: server.nickname,
        source: "alice!user@host.example.com",
        text: "Hello there!"
      }
    })

    assert_selector ".dm-item", text: "alice", wait: 5
  end

  test "channel join appears in sidebar" do
    server = @user.servers.create!(
      address: "#{@test_id}-join.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    channel = Channel.create!(server: server, name: "#test-#{@test_id}", joined: false)

    sign_in_user
    visit server_path(server)

    within ".channels-section" do
      assert_no_selector ".channel-item", text: "#test-#{@test_id}"
    end

    IrcEventHandler.handle(server, {
      type: "join",
      data: {
        target: channel.name,
        source: "#{server.nickname}!user@host.example.com"
      }
    })

    within ".channels-section" do
      assert_selector ".channel-item", text: "#test-#{@test_id}", wait: 5
    end
  end

  test "channel leave removes from sidebar" do
    server = @user.servers.create!(
      address: "#{@test_id}-leave.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    channel = Channel.create!(server: server, name: "#test-#{@test_id}", joined: true)

    sign_in_user
    visit server_path(server)

    within ".channels-section" do
      assert_selector ".channel-item", text: "#test-#{@test_id}"
    end

    IrcEventHandler.handle(server, {
      type: "part",
      data: {
        target: channel.name,
        source: "#{server.nickname}!user@host.example.com",
        text: "Goodbye"
      }
    })

    within ".channels-section" do
      assert_no_selector ".channel-item", text: "#test-#{@test_id}", wait: 5
    end
  end

  test "unread count updates in sidebar" do
    server = @user.servers.create!(
      address: "#{@test_id}-unread.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    channel = Channel.create!(server: server, name: "#general-#{@test_id}", joined: true)
    other_channel = Channel.create!(server: server, name: "#other-#{@test_id}", joined: true)

    initial_message = Message.create!(
      server: server,
      channel: other_channel,
      sender: "system",
      content: "Initial message",
      message_type: "notice"
    )
    other_channel.update!(last_read_message_id: initial_message.id)

    sign_in_user
    visit channel_path(channel)

    assert_selector ".channel-item", text: "#other-#{@test_id}"
    within(".channel-item", text: "#other-#{@test_id}") do
      assert_no_selector ".badge"
    end

    Current.user_id = @user.id
    IrcEventHandler.handle(server, {
      type: "message",
      data: {
        target: other_channel.name,
        source: "alice!user@host.example.com",
        text: "Hello!"
      }
    })

    within(".channel-item", text: "#other-#{@test_id}") do
      assert_selector ".badge", text: "1", wait: 5
    end
  ensure
    Current.user_id = nil
  end
end
