require "application_system_test_case"

class DmOnlineStatusTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)
  end

  test "DM shows online indicator when user is in shared channel" do
    server = @user.servers.create!(
      address: "#{@test_id}-online.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    channel = Channel.create!(server: server, name: "#ruby", joined: true)
    ChannelUser.create!(channel: channel, nickname: "alice")
    Conversation.create!(server: server, target_nick: "alice")

    sign_in_as(@user)
    visit channel_path(channel)

    within ".channel-sidebar" do
      dm_item = find(".dm-item", text: "alice")
      indicator = dm_item.find(".presence-indicator")
      assert indicator[:class].include?("-online")
    end
  end

  test "DM shows offline indicator when user is not in any channel" do
    server = @user.servers.create!(
      address: "#{@test_id}-offline.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    channel = Channel.create!(server: server, name: "#ruby", joined: true)
    Conversation.create!(server: server, target_nick: "bob")

    sign_in_as(@user)
    visit channel_path(channel)

    within ".channel-sidebar" do
      dm_item = find(".dm-item", text: "bob")
      indicator = dm_item.find(".presence-indicator")
      assert indicator[:class].include?("-offline")
    end
  end

  test "indicator updates when user joins channel and broadcast is triggered" do
    server = @user.servers.create!(
      address: "#{@test_id}-join.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    channel = Channel.create!(server: server, name: "#ruby-#{@test_id}", joined: true)
    conversation = Conversation.create!(server: server, target_nick: "alice")

    sign_in_as(@user)
    visit channel_path(channel)

    within ".channel-sidebar" do
      dm_item = find(".dm-item", text: "alice")
      indicator = dm_item.find(".presence-indicator")
      assert indicator[:class].include?("-offline")
    end

    IrcEventHandler.handle(server, {
      type: "join",
      data: {
        target: channel.name,
        source: "alice!user@host.example.com"
      }
    })

    conversation.broadcast_presence_update

    within ".channel-sidebar" do
      assert_selector ".dm-item .presence-indicator.-online", wait: 5
    end
  end

  test "indicator updates when user leaves channel and broadcast is triggered" do
    server = @user.servers.create!(
      address: "#{@test_id}-leave.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    channel = Channel.create!(server: server, name: "#ruby-#{@test_id}", joined: true)
    ChannelUser.create!(channel: channel, nickname: "alice")
    conversation = Conversation.create!(server: server, target_nick: "alice")

    sign_in_as(@user)
    visit channel_path(channel)

    within ".channel-sidebar" do
      dm_item = find(".dm-item", text: "alice")
      indicator = dm_item.find(".presence-indicator")
      assert indicator[:class].include?("-online")
    end

    IrcEventHandler.handle(server, {
      type: "part",
      data: {
        target: channel.name,
        source: "alice!user@host.example.com",
        text: "Goodbye"
      }
    })

    conversation.broadcast_presence_update

    within ".channel-sidebar" do
      assert_selector ".dm-item .presence-indicator.-offline", wait: 5
    end
  end
end
