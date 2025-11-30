require "application_system_test_case"

class LayoutTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)
  end

  def sign_in_user
    visit new_session_path
    fill_in "email_address", with: @user.email_address
    fill_in "password", with: "password123"
    click_button "Sign in"
  end

  def create_server_with_channel
    server = @user.servers.create!(
      address: "#{@test_id}-irc.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    Channel.create!(server: server, name: "#test", joined: true)
    server
  end

  test "desktop shows all three columns" do
    create_server_with_channel
    sign_in_user

    assert_selector ".app-layout"
    assert_selector ".sidebar"
    assert_selector ".main"
  end

  test "sidebar shows servers and channels" do
    create_server_with_channel
    sign_in_user

    assert_selector "[data-qa='server-group']"
    assert_selector "[data-qa='channel-item']"
  end

  test "clicking channel navigates to channel" do
    server = create_server_with_channel
    channel = server.channels.first
    sign_in_user

    find("[data-qa='channel-link']", text: "#test").click
    assert_selector ".channel-view .name", text: "#test"
    assert_current_path channel_path(channel)
  end

  test "logo links to root" do
    create_server_with_channel
    sign_in_user

    click_link "IRC Client"
    assert_current_path root_path
  end

  test "header shows user email" do
    create_server_with_channel
    sign_in_user

    assert_selector "[data-qa='user-email']", text: @user.email_address
  end

  test "sign out button works" do
    create_server_with_channel
    sign_in_user

    click_button "Sign out"
    assert_current_path new_session_path
  end
end
