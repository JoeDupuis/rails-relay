require "application_system_test_case"

class CloseDmTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)
  end

  def create_server_with_dm
    server = @user.servers.create!(
      address: "#{@test_id}-irc.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    conversation = Conversation.create!(server: server, target_nick: "alice")
    [ server, conversation ]
  end

  def create_server_with_channel_and_user
    server = @user.servers.create!(
      address: "#{@test_id}-irc.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    channel = Channel.create!(server: server, name: "#test", joined: true)
    ChannelUser.create!(channel: channel, nickname: "bob", modes: "")
    [ server, channel ]
  end

  test "close button appears on DM item hover" do
    server, conversation = create_server_with_dm
    sign_in_as(@user)

    visit servers_path
    dm_item = find(".dm-item", text: "alice")

    dm_item.hover
    assert_selector ".dm-item .close-btn"
  end

  test "clicking close removes DM from sidebar and redirects to server" do
    server, conversation = create_server_with_dm
    sign_in_as(@user)

    visit conversation_path(conversation)
    assert_selector ".channel-sidebar .dm-item", text: "alice"

    dm_item = find(".dm-item", text: "alice")
    dm_item.hover
    within dm_item do
      click_button(class: "close-btn")
    end

    assert_no_selector ".channel-sidebar .dm-item", text: "alice"
    assert_current_path server_path(server)
  end

  test "closed DM reappears on new message" do
    server, conversation = create_server_with_dm
    conversation.close!
    sign_in_as(@user)

    visit servers_path
    assert_no_selector ".dm-item", text: "alice"

    IrcEventHandler.handle(server, {
      type: "message",
      data: {
        source: "alice!user@host",
        target: "testnick",
        text: "Hey!"
      }
    })
    conversation.reload.broadcast_sidebar_add

    assert_selector ".dm-item", text: "alice"
  end

  test "clicking username reopens closed DM" do
    server, channel = create_server_with_channel_and_user
    closed_convo = Conversation.create!(server: server, target_nick: "bob", closed_at: Time.current)
    sign_in_as(@user)

    visit channel_path(channel)
    assert_no_selector ".channel-sidebar .dm-item", text: "bob"

    within ".user-list" do
      click_link "bob"
    end

    assert_selector ".channel-sidebar .dm-item", text: "bob"
    assert_current_path conversation_path(closed_convo)
  end
end
