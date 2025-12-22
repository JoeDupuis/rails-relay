require "application_system_test_case"

class ClickableLinksTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)
    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_return(status: 200, body: { success: true }.to_json)
  end

  def create_server_with_channel
    server = @user.servers.create!(
      address: "#{@test_id}-irc.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    Channel.create!(server: server, name: "#test", joined: true)
  end

  test "URLs in chat messages are rendered as clickable links" do
    channel = create_server_with_channel
    Message.create!(
      channel: channel,
      server: channel.server,
      sender: "alice",
      message_type: "privmsg",
      content: "Check out https://example.com for more info"
    )

    sign_in_as(@user)
    visit channel_path(channel)

    assert_selector ".message-item"

    within ".message-item .content" do
      link = find("a[href='https://example.com']")
      assert_equal "_blank", link[:target]
      assert_equal "noopener noreferrer", link[:rel]
      assert_text "https://example.com"
    end
  end

  test "uploaded file URLs in messages are clickable" do
    channel = create_server_with_channel
    Message.create!(
      channel: channel,
      server: channel.server,
      sender: "bob",
      message_type: "privmsg",
      content: "Here's the file: https://localhost/rails/active_storage/blobs/abc123/file.png"
    )

    sign_in_as(@user)
    visit channel_path(channel)

    assert_selector ".message-item"

    within ".message-item .content" do
      link = find("a", match: :first)
      assert link[:href].include?("active_storage")
      assert_equal "_blank", link[:target]
    end
  end

  test "multiple URLs in same message are all clickable" do
    channel = create_server_with_channel
    Message.create!(
      channel: channel,
      server: channel.server,
      sender: "alice",
      message_type: "privmsg",
      content: "See https://first.com and also https://second.com"
    )

    sign_in_as(@user)
    visit channel_path(channel)

    within ".message-item .content" do
      assert_selector "a[href='https://first.com']"
      assert_selector "a[href='https://second.com']"
    end
  end

  test "messages without URLs render normally" do
    channel = create_server_with_channel
    Message.create!(
      channel: channel,
      server: channel.server,
      sender: "alice",
      message_type: "privmsg",
      content: "Just a normal message"
    )

    sign_in_as(@user)
    visit channel_path(channel)

    within ".message-item .content" do
      assert_text "Just a normal message"
      assert_no_selector "a"
    end
  end

  test "HTML in messages is escaped even with URLs" do
    channel = create_server_with_channel
    Message.create!(
      channel: channel,
      server: channel.server,
      sender: "alice",
      message_type: "privmsg",
      content: "<script>alert('xss')</script> https://example.com"
    )

    sign_in_as(@user)
    visit channel_path(channel)

    within ".message-item .content" do
      assert_text "<script>"
      assert_no_selector "script"
      assert_selector "a[href='https://example.com']"
    end
  end
end
