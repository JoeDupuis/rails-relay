require "test_helper"

class ChannelUserTest < ActiveSupport::TestCase
  setup do
    @user = users(:joe)
  end

  test "validates nickname presence" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    channel_user = ChannelUser.new(channel: channel, nickname: "")
    assert_not channel_user.valid?
    assert_includes channel_user.errors[:nickname], "can't be blank"
  end

  test "validates uniqueness of nickname per channel" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    ChannelUser.create!(channel: channel, nickname: "user1")
    channel_user = ChannelUser.new(channel: channel, nickname: "user1")
    assert_not channel_user.valid?
    assert_includes channel_user.errors[:nickname], "has already been taken"
  end

  test "allows same nickname in different channels" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel1 = Channel.create!(server: server, name: "#ruby")
    channel2 = Channel.create!(server: server, name: "#python")
    ChannelUser.create!(channel: channel1, nickname: "user1")
    channel_user = ChannelUser.new(channel: channel2, nickname: "user1")
    assert channel_user.valid?
  end

  test "op? returns true when modes includes o" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    channel_user = ChannelUser.create!(channel: channel, nickname: "user1", modes: "o")
    assert channel_user.op?
  end

  test "op? returns false when modes does not include o" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    channel_user = ChannelUser.create!(channel: channel, nickname: "user1", modes: "v")
    assert_not channel_user.op?
  end

  test "op? returns false when modes is nil" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    channel_user = ChannelUser.create!(channel: channel, nickname: "user1")
    assert_not channel_user.op?
  end

  test "voiced? returns true when modes includes v" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    channel_user = ChannelUser.create!(channel: channel, nickname: "user1", modes: "v")
    assert channel_user.voiced?
  end

  test "voiced? returns false when modes does not include v" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    channel_user = ChannelUser.create!(channel: channel, nickname: "user1", modes: "o")
    assert_not channel_user.voiced?
  end

  test "voiced? returns false when modes is nil" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    channel_user = ChannelUser.create!(channel: channel, nickname: "user1")
    assert_not channel_user.voiced?
  end

  test "ops scope returns users with o mode" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    op_user = ChannelUser.create!(channel: channel, nickname: "op", modes: "o")
    voiced_user = ChannelUser.create!(channel: channel, nickname: "voiced", modes: "v")
    regular_user = ChannelUser.create!(channel: channel, nickname: "regular")

    ops = channel.channel_users.ops
    assert_includes ops, op_user
    assert_not_includes ops, voiced_user
    assert_not_includes ops, regular_user
  end

  test "voiced scope returns users with v mode" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    op_user = ChannelUser.create!(channel: channel, nickname: "op", modes: "o")
    voiced_user = ChannelUser.create!(channel: channel, nickname: "voiced", modes: "v")
    regular_user = ChannelUser.create!(channel: channel, nickname: "regular")

    voiced = channel.channel_users.voiced
    assert_not_includes voiced, op_user
    assert_includes voiced, voiced_user
    assert_not_includes voiced, regular_user
  end

  test "regular scope returns users without o or v mode" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    op_user = ChannelUser.create!(channel: channel, nickname: "op", modes: "o")
    voiced_user = ChannelUser.create!(channel: channel, nickname: "voiced", modes: "v")
    regular_user = ChannelUser.create!(channel: channel, nickname: "regular")

    regular = channel.channel_users.regular
    assert_not_includes regular, op_user
    assert_not_includes regular, voiced_user
    assert_includes regular, regular_user
  end

  test "belongs to channel" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    channel_user = ChannelUser.create!(channel: channel, nickname: "user1")
    assert_equal channel, channel_user.channel
  end

  test "broadcasts user list when user is created" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")

    assert_turbo_stream_broadcasts [ channel, :users ] do
      ChannelUser.create!(channel: channel, nickname: "newuser")
    end
  end

  test "broadcasts user list when user is destroyed" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    channel_user = ChannelUser.create!(channel: channel, nickname: "olduser")

    assert_turbo_stream_broadcasts [ channel, :users ] do
      channel_user.destroy
    end
  end

  test "broadcasts user list when modes change" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    channel_user = ChannelUser.create!(channel: channel, nickname: "user1")

    assert_turbo_stream_broadcasts [ channel, :users ] do
      channel_user.update!(modes: "o")
    end
  end

  test "does not broadcast when modes unchanged" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    channel_user = ChannelUser.create!(channel: channel, nickname: "user1", modes: "o")

    ActionCable.server.pubsub.clear_messages(stream_name_for(channel, :users))

    assert_no_turbo_stream_broadcasts [ channel, :users ] do
      channel_user.update!(nickname: "user1renamed")
    end
  end

  test "broadcasts DM sidebar update when user joins and has conversation" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    Conversation.create!(server: server, target_nick: "alice")

    assert_turbo_stream_broadcasts "sidebar_#{@user.id}" do
      ChannelUser.create!(channel: channel, nickname: "alice")
    end
  end

  test "broadcasts DM sidebar update when user leaves and has conversation" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    Conversation.create!(server: server, target_nick: "alice")
    channel_user = ChannelUser.create!(channel: channel, nickname: "alice")

    ActionCable.server.pubsub.clear_messages(stream_name_for(channel, :users))

    assert_turbo_stream_broadcasts "sidebar_#{@user.id}" do
      channel_user.destroy
    end
  end

  test "does not broadcast DM sidebar update when user has no conversation" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")

    ActionCable.server.pubsub.clear_messages("sidebar_#{@user.id}")

    assert_no_turbo_stream_broadcasts "sidebar_#{@user.id}" do
      ChannelUser.create!(channel: channel, nickname: "alice")
    end
  end

  test "broadcasts DM sidebar update case-insensitively" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")
    Conversation.create!(server: server, target_nick: "Alice")

    assert_turbo_stream_broadcasts "sidebar_#{@user.id}" do
      ChannelUser.create!(channel: channel, nickname: "alice")
    end
  end

  private

  def stream_name_for(*streamables)
    streamables.map { |s| s.try(:to_gid_param) || s.to_param }.join(":")
  end
end
