require "application_system_test_case"

class MobileUserlistDrawerTest < ApplicationSystemTestCase
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
    sign_in_user
    visit channel_path(channel)

    assert_selector ".userlist-toggle", visible: true
    assert_selector ".userlist", visible: :hidden
  end

  test "toggle button hidden on desktop" do
    _server, channel = create_server_with_channel_and_users
    page.driver.browser.resize(width: 1200, height: 800)
    sign_in_user
    visit channel_path(channel)

    assert_selector ".userlist-toggle", visible: :hidden
    assert_selector ".userlist", visible: true
  end

  test "open drawer" do
    _server, channel = create_server_with_channel_and_users
    page.driver.browser.resize(width: 768, height: 1024)
    sign_in_user
    visit channel_path(channel)

    assert_no_selector ".userlist-drawer.-open"
    assert_no_selector ".userlist-backdrop.-visible"

    find(".userlist-toggle").click

    assert_selector ".userlist-drawer.-open"
    assert_selector ".userlist-backdrop.-visible"
  end

  test "close drawer with X button" do
    _server, channel = create_server_with_channel_and_users
    page.driver.browser.resize(width: 768, height: 1024)
    sign_in_user
    visit channel_path(channel)

    find(".userlist-toggle").click
    assert_selector ".userlist-drawer.-open"

    find(".userlist-drawer .close").click

    assert_no_selector ".userlist-drawer.-open"
    assert_no_selector ".userlist-backdrop.-visible"
  end

  test "close drawer by clicking backdrop" do
    _server, channel = create_server_with_channel_and_users
    page.driver.browser.resize(width: 768, height: 1024)
    sign_in_user
    visit channel_path(channel)

    find(".userlist-toggle").click
    assert_selector ".userlist-drawer.-open"

    find(".userlist-backdrop.-visible").click

    assert_no_selector ".userlist-drawer.-open"
    assert_no_selector ".userlist-backdrop.-visible"
  end

  test "close drawer with Escape key" do
    _server, channel = create_server_with_channel_and_users
    page.driver.browser.resize(width: 768, height: 1024)
    sign_in_user
    visit channel_path(channel)

    find(".userlist-toggle").click
    assert_selector ".userlist-drawer.-open"

    find(".userlist-drawer .close").send_keys :escape

    assert_no_selector ".userlist-drawer.-open"
    assert_no_selector ".userlist-backdrop.-visible"
  end

  test "drawer shows user list content" do
    _server, channel = create_server_with_channel_and_users
    page.driver.browser.resize(width: 768, height: 1024)
    sign_in_user
    visit channel_path(channel)

    find(".userlist-toggle").click

    within ".userlist-drawer" do
      assert_text "Users (3)"
      assert_text "Operators"
      assert_text "op_user"
      assert_text "Voiced"
      assert_text "voiced_user"
      assert_text "regular_user"
    end
  end
end
