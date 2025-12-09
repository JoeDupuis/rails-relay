require "application_system_test_case"

class MobileLayoutTest < ApplicationSystemTestCase
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

  def create_server
    @user.servers.create!(
      address: "#{@test_id}-irc.example.chat",
      nickname: "testnick"
    )
  end

  def create_server_with_channel
    server = create_server
    Channel.create!(server: server, name: "#test", joined: true)
    ChannelUser.create!(channel: server.channels.first, nickname: "testnick", modes: "")
    server
  end

  test "server page layout on mobile viewport" do
    server = create_server
    page.driver.browser.resize(width: 768, height: 1024)
    sign_in_user
    visit server_path(server)

    assert_selector ".app-layout.-no-userlist"
    assert_selector ".server-view"

    main_width = page.evaluate_script("document.querySelector('.main').getBoundingClientRect().width")
    viewport_width = page.evaluate_script("window.innerWidth")

    assert main_width > viewport_width * 0.9, "Main content should fill nearly full viewport width (got #{main_width}px of #{viewport_width}px)"
  end

  test "server page layout on tablet viewport" do
    server = create_server
    page.driver.browser.resize(width: 900, height: 1200)
    sign_in_user
    visit server_path(server)

    assert_selector ".app-layout.-no-userlist"
    assert_selector ".server-view"

    main_width = page.evaluate_script("document.querySelector('.main').getBoundingClientRect().width")
    viewport_width = page.evaluate_script("window.innerWidth")

    assert main_width > viewport_width * 0.9, "Main content should fill nearly full viewport width (got #{main_width}px of #{viewport_width}px)"
  end

  test "server page layout on desktop viewport" do
    server = create_server
    page.driver.browser.resize(width: 1200, height: 800)
    sign_in_user
    visit server_path(server)

    assert_selector ".app-layout.-no-userlist"
    assert_selector ".server-view"
    assert_selector ".sidebar"

    sidebar_width = page.evaluate_script("document.querySelector('.sidebar').getBoundingClientRect().width")
    main_left = page.evaluate_script("document.querySelector('.main').getBoundingClientRect().left")

    assert_in_delta 240, sidebar_width, 10, "Sidebar should be ~240px wide"
    assert main_left >= 200, "Main content should be positioned after sidebar (got left: #{main_left}px)"
  end

  test "channel page still works on mobile" do
    server = create_server_with_channel
    channel = server.channels.first
    page.driver.browser.resize(width: 768, height: 1024)
    sign_in_user
    visit channel_path(channel)

    assert_selector ".channel-view"

    main_width = page.evaluate_script("document.querySelector('.main').getBoundingClientRect().width")
    viewport_width = page.evaluate_script("window.innerWidth")

    assert main_width > viewport_width * 0.9, "Channel main content should fill nearly full viewport width"

    userlist_left = page.evaluate_script("document.querySelector('.userlist').getBoundingClientRect().left")
    assert userlist_left >= viewport_width, "Userlist should be positioned off-screen on mobile"
  end
end
