require "application_system_test_case"

class MessageDraftTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)
    stub_irc_command
  end

  def create_connected_channel(name = "#drafts")
    server = @user.servers.create!(
      address: "#{@test_id}-irc.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    Channel.create!(server: server, name: name, joined: true)
  end

  test "draft survives a page refresh when returning to the app" do
    channel = create_connected_channel
    sign_in_as(@user)
    visit channel_path(channel)

    find(".message-input .field").fill_in(with: "half typed thought")
    page.execute_script("Turbo.session.refresh(window.location.href)")
    sleep 0.5

    assert_field "content", with: "half typed thought"
  end

  test "draft survives a full page reload" do
    channel = create_connected_channel
    sign_in_as(@user)
    visit channel_path(channel)

    find(".message-input .field").fill_in(with: "still here")
    visit channel_path(channel)

    assert_field "content", with: "still here"
  end

  test "drafts are kept per channel" do
    channel = create_connected_channel
    other = Channel.create!(server: channel.server, name: "#elsewhere", joined: true)
    sign_in_as(@user)
    visit channel_path(channel)

    find(".message-input .field").fill_in(with: "for drafts only")
    visit channel_path(other)

    assert_field "content", with: ""
  end

  test "draft is cleared after sending" do
    channel = create_connected_channel
    sign_in_as(@user)
    visit channel_path(channel)

    find(".message-input .field").fill_in(with: "sending this")
    find(".message-input .field").send_keys(:enter)
    assert_field "content", with: ""

    visit channel_path(channel)
    assert_field "content", with: ""
  end
end
