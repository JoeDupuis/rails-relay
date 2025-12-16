require "application_system_test_case"

class MobileUserlistDrawerTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)
  end

  def create_server_with_channel_and_users
    server = @user.servers.create!(
      address: "#{@test_id}-irc.example.chat",
      nickname: "testnick"
    )
    channel = Channel.create!(server: server, name: "#test", joined: true)
    ChannelUser.create!(channel: channel, nickname: "op_user", modes: "o")
    ChannelUser.create!(channel: channel, nickname: "voiced_user", modes: "v")
    ChannelUser.create!(channel: channel, nickname: "regular_user", modes: "")
    [ server, channel ]
  end

  test "toggle button visible on mobile" do
    _server, channel = create_server_with_channel_and_users
    page.driver.browser.resize(width: 768, height: 1024)
    sign_in_as(@user)
    visit channel_path(channel)

    assert_selector ".userlist-toggle", visible: true
    userlist_left = page.evaluate_script("document.querySelector('.userlist').getBoundingClientRect().left")
    viewport_width = page.evaluate_script("window.innerWidth")
    assert userlist_left >= viewport_width, "Userlist should be positioned off-screen on mobile"
  end

  test "toggle button hidden on desktop" do
    _server, channel = create_server_with_channel_and_users
    page.driver.browser.resize(width: 1200, height: 800)
    sign_in_as(@user)
    visit channel_path(channel)

    assert_selector ".userlist-toggle", visible: :hidden
    assert_selector ".userlist", visible: true
  end

  test "open drawer" do
    _server, channel = create_server_with_channel_and_users
    page.driver.browser.resize(width: 768, height: 1024)
    sign_in_as(@user)
    visit channel_path(channel)

    assert_no_selector ".userlist.-open"
    assert_no_selector ".userlist-backdrop.-visible"

    find(".userlist-toggle").click

    assert_selector ".userlist.-open"
    assert_selector ".userlist-backdrop.-visible"
  end

  test "close drawer with X button" do
    _server, channel = create_server_with_channel_and_users
    page.driver.browser.resize(width: 768, height: 1024)
    sign_in_as(@user)
    visit channel_path(channel)

    find(".userlist-toggle").click
    assert_selector ".userlist.-open"

    find(".userlist .close").click

    assert_no_selector ".userlist.-open"
    assert_no_selector ".userlist-backdrop.-visible"
  end

  test "close drawer by clicking backdrop" do
    _server, channel = create_server_with_channel_and_users
    page.driver.browser.resize(width: 768, height: 1024)
    sign_in_as(@user)
    visit channel_path(channel)

    find(".userlist-toggle").click
    assert_selector ".userlist.-open"

    find(".userlist-backdrop.-visible").click

    assert_no_selector ".userlist.-open"
    assert_no_selector ".userlist-backdrop.-visible"
  end

  test "close drawer with Escape key" do
    _server, channel = create_server_with_channel_and_users
    page.driver.browser.resize(width: 768, height: 1024)
    sign_in_as(@user)
    visit channel_path(channel)

    find(".userlist-toggle").click
    assert_selector ".userlist.-open"

    find(".userlist .close").send_keys :escape

    assert_no_selector ".userlist.-open"
    assert_no_selector ".userlist-backdrop.-visible"
  end

  test "drawer shows user list content" do
    _server, channel = create_server_with_channel_and_users
    page.driver.browser.resize(width: 768, height: 1024)
    sign_in_as(@user)
    visit channel_path(channel)

    find(".userlist-toggle").click

    within ".userlist" do
      assert_text "3 users"
      assert_text "Operators"
      assert_text "op_user"
      assert_text "Voiced"
      assert_text "voiced_user"
      assert_text "regular_user"
    end
  end

  test "user list not duplicated in HTML" do
    _server, channel = create_server_with_channel_and_users
    page.driver.browser.resize(width: 768, height: 1024)
    sign_in_as(@user)
    visit channel_path(channel)

    user_list_count = page.all(".user-list", visible: :all).count
    assert_equal 1, user_list_count, "Expected exactly one user list element, found #{user_list_count}"
  end

  test "live update works on mobile drawer open" do
    server, channel = create_server_with_channel_and_users
    page.driver.browser.resize(width: 768, height: 1024)
    sign_in_as(@user)
    visit channel_path(channel)

    find(".userlist-toggle").click
    assert_selector ".userlist.-open"

    within ".userlist" do
      assert_text "3 users"
      assert_no_text "new_joiner"
    end

    ChannelUser.create!(channel: channel, nickname: "new_joiner", modes: "")
    channel.broadcast_replace_to(
      [ channel, :users ],
      target: "channel_#{channel.id}_user_list",
      partial: "channels/user_list",
      locals: { channel: channel.reload }
    )

    within ".userlist" do
      assert_text "4 users"
      assert_text "new_joiner"
    end

    assert_selector ".userlist.-open"
  end

  test "toggle button count updates live when user joins" do
    server, channel = create_server_with_channel_and_users
    page.driver.browser.resize(width: 768, height: 1024)
    sign_in_as(@user)
    visit channel_path(channel)

    assert_selector ".userlist-toggle .count", text: "3"

    IrcEventHandler.handle(server, {
      type: "join",
      data: {
        target: channel.name,
        source: "newuser!user@host.example.com"
      }
    })

    assert_selector ".userlist-toggle .count", text: "4", wait: 5
  end

  test "toggle button count updates live when user parts" do
    server, channel = create_server_with_channel_and_users
    page.driver.browser.resize(width: 768, height: 1024)
    sign_in_as(@user)
    visit channel_path(channel)

    assert_selector ".userlist-toggle .count", text: "3"

    IrcEventHandler.handle(server, {
      type: "part",
      data: {
        target: channel.name,
        source: "regular_user!user@host.example.com",
        text: "Leaving"
      }
    })

    assert_selector ".userlist-toggle .count", text: "2", wait: 5
  end
end
