require "test_helper"

class IrcEventHandlerTest < ActiveSupport::TestCase
  setup do
    @user = users(:joe)
  end

  test "handle_message creates channel message" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")

    event = {
      type: "message",
      data: {
        source: "john!john@example.com",
        target: "#ruby",
        text: "Hello everyone"
      }
    }

    assert_difference "Message.count", 1 do
      IrcEventHandler.handle(server, event)
    end

    message = Message.last
    assert_equal server, message.server
    assert_equal "#ruby", message.channel.name
    assert_equal "john", message.sender
    assert_equal "Hello everyone", message.content
    assert_equal "privmsg", message.message_type
  end

  test "handle_message creates PM with notification" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")

    event = {
      type: "message",
      data: {
        source: "john!john@example.com",
        target: "testnick",
        text: "Private message"
      }
    }

    assert_difference [ "Message.count", "Notification.count" ], 1 do
      IrcEventHandler.handle(server, event)
    end

    message = Message.last
    assert_equal server, message.server
    assert_nil message.channel
    assert_equal "john", message.target
    assert_equal "john", message.sender
    assert_equal "Private message", message.content
    assert_equal "privmsg", message.message_type
    assert_equal "dm", message.notification.reason
  end

  test "handle_message detects highlight" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")

    event = {
      type: "message",
      data: {
        source: "john!john@example.com",
        target: "#ruby",
        text: "Hey testnick, how are you?"
      }
    }

    assert_difference "Notification.count", 1 do
      IrcEventHandler.handle(server, event)
    end

    notification = Notification.last
    assert_equal "highlight", notification.reason
  end

  test "handle_join marks channel as joined when we join" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")

    event = {
      type: "join",
      data: {
        source: "testnick!user@host",
        target: "#ruby"
      }
    }

    IrcEventHandler.handle(server, event)

    channel = Channel.find_by(name: "#ruby")
    assert channel.joined
  end

  test "handle_join creates channel_user when other joins" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby", joined: true)

    event = {
      type: "join",
      data: {
        source: "john!john@example.com",
        target: "#ruby"
      }
    }

    assert_difference "channel.channel_users.count", 1 do
      IrcEventHandler.handle(server, event)
    end

    assert channel.channel_users.exists?(nickname: "john")
  end

  test "handle_part marks channel as not joined when we part" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby", joined: true)
    channel.channel_users.create!(nickname: "john")

    event = {
      type: "part",
      data: {
        source: "testnick!user@host",
        target: "#ruby",
        text: "Leaving"
      }
    }

    IrcEventHandler.handle(server, event)

    channel.reload
    assert_not channel.joined
    assert_equal 0, channel.channel_users.count
  end

  test "handle_part removes channel_user when other parts" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby", joined: true)
    channel.channel_users.create!(nickname: "john")

    event = {
      type: "part",
      data: {
        source: "john!john@example.com",
        target: "#ruby",
        text: "bye"
      }
    }

    assert_difference "channel.channel_users.count", -1 do
      IrcEventHandler.handle(server, event)
    end

    assert_not channel.channel_users.exists?(nickname: "john")
  end

  test "handle_quit removes user from all channels" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel1 = Channel.create!(server: server, name: "#ruby", joined: true)
    channel2 = Channel.create!(server: server, name: "#python", joined: true)
    channel1.channel_users.create!(nickname: "john")
    channel2.channel_users.create!(nickname: "john")

    event = {
      type: "quit",
      data: {
        source: "john!john@example.com",
        text: "Quit: Gone"
      }
    }

    IrcEventHandler.handle(server, event)

    assert_not channel1.channel_users.exists?(nickname: "john")
    assert_not channel2.channel_users.exists?(nickname: "john")
  end

  test "handle_action creates action message" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    Channel.create!(server: server, name: "#ruby")

    event = {
      type: "action",
      data: {
        source: "john!john@example.com",
        target: "#ruby",
        text: "waves hello"
      }
    }

    assert_difference "Message.count", 1 do
      IrcEventHandler.handle(server, event)
    end

    message = Message.last
    assert_equal "action", message.message_type
    assert_equal "waves hello", message.content
  end

  test "handle_notice creates notice message" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby")

    event = {
      type: "notice",
      data: {
        source: "ChanServ!service@irc",
        target: "#ruby",
        text: "This channel is registered"
      }
    }

    assert_difference "Message.count", 1 do
      IrcEventHandler.handle(server, event)
    end

    message = Message.last
    assert_equal "notice", message.message_type
    assert_equal channel, message.channel
  end

  test "handle_kick removes user and creates kick message" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby", joined: true)
    channel.channel_users.create!(nickname: "baduser")

    event = {
      type: "kick",
      data: {
        source: "op!op@host",
        target: "#ruby",
        kicked: "baduser",
        text: "Bye"
      }
    }

    IrcEventHandler.handle(server, event)

    assert_not channel.channel_users.exists?(nickname: "baduser")
    message = Message.last
    assert_equal "kick", message.message_type
    assert_includes message.content, "baduser was kicked"
  end

  test "handle_nick updates user in all channels" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel1 = Channel.create!(server: server, name: "#ruby", joined: true)
    channel2 = Channel.create!(server: server, name: "#python", joined: true)
    channel1.channel_users.create!(nickname: "john")
    channel2.channel_users.create!(nickname: "john")

    event = {
      type: "nick",
      data: {
        source: "john!john@example.com",
        new_nick: "johnny"
      }
    }

    IrcEventHandler.handle(server, event)

    assert channel1.channel_users.exists?(nickname: "johnny")
    assert channel2.channel_users.exists?(nickname: "johnny")
    assert_not channel1.channel_users.exists?(nickname: "john")
    assert_not channel2.channel_users.exists?(nickname: "john")

    message = Message.last
    assert_equal "nick", message.message_type
    assert_equal "john", message.sender
    assert_equal "johnny", message.content
  end

  test "handle_nick updates server nickname when own nick changes" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "joe")

    event = {
      type: "nick",
      data: {
        source: "joe!joe@example.com",
        new_nick: "joe_"
      }
    }

    IrcEventHandler.handle(server, event)

    assert_equal "joe_", server.reload.nickname
  end

  test "handle_nick updates server nickname case-insensitively" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "Joe")

    event = {
      type: "nick",
      data: {
        source: "joe!joe@example.com",
        new_nick: "joe_"
      }
    }

    IrcEventHandler.handle(server, event)

    assert_equal "joe_", server.reload.nickname
  end

  test "handle_nick does not update server nickname for other users" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "joe")
    channel = Channel.create!(server: server, name: "#ruby", joined: true)
    channel.channel_users.create!(nickname: "bob")

    event = {
      type: "nick",
      data: {
        source: "bob!bob@example.com",
        new_nick: "bobby"
      }
    }

    IrcEventHandler.handle(server, event)

    assert_equal "joe", server.reload.nickname
  end

  test "handle_nick still updates channel_users for own nick" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "joe")
    channel = Channel.create!(server: server, name: "#ruby", joined: true)
    channel.channel_users.create!(nickname: "joe")

    event = {
      type: "nick",
      data: {
        source: "joe!joe@example.com",
        new_nick: "joe_"
      }
    }

    IrcEventHandler.handle(server, event)

    assert_equal "joe_", server.reload.nickname
    assert channel.channel_users.exists?(nickname: "joe_")
    assert_not channel.channel_users.exists?(nickname: "joe")
  end

  test "handle_topic updates channel topic" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby", joined: true)

    event = {
      type: "topic",
      data: {
        source: "op!op@host",
        target: "#ruby",
        text: "Welcome to Ruby!"
      }
    }

    IrcEventHandler.handle(server, event)

    channel.reload
    assert_equal "Welcome to Ruby!", channel.topic

    message = Message.last
    assert_equal "topic", message.message_type
  end

  test "handle_names creates channel_users with modes" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby", joined: true)

    event = {
      type: "names",
      data: {
        channel: "#ruby",
        names: [ "@opuser", "+voiceuser", "regularuser" ]
      }
    }

    IrcEventHandler.handle(server, event)

    op_user = channel.channel_users.find_by(nickname: "opuser")
    assert_equal "o", op_user.modes
    assert op_user.op?

    voice_user = channel.channel_users.find_by(nickname: "voiceuser")
    assert_equal "v", voice_user.modes
    assert voice_user.voiced?

    regular_user = channel.channel_users.find_by(nickname: "regularuser")
    assert_equal "", regular_user.modes
  end

  test "handle_names clears existing users first" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#ruby", joined: true)
    channel.channel_users.create!(nickname: "olduser1")
    channel.channel_users.create!(nickname: "olduser2")

    event = {
      type: "names",
      data: {
        channel: "#ruby",
        names: [ "newuser1", "newuser2" ]
      }
    }

    IrcEventHandler.handle(server, event)

    assert_equal 2, channel.channel_users.count
    assert_not channel.channel_users.exists?(nickname: "olduser1")
    assert_not channel.channel_users.exists?(nickname: "olduser2")
    assert channel.channel_users.exists?(nickname: "newuser1")
    assert channel.channel_users.exists?(nickname: "newuser2")
  end

  test "handle_connected sets connected_at" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")

    event = { type: "connected" }

    IrcEventHandler.handle(server, event)

    assert_not_nil server.reload.connected_at
  end

  test "handle_disconnected clears connected_at" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick", connected_at: Time.current)

    event = { type: "disconnected" }

    IrcEventHandler.handle(server, event)

    assert_nil server.reload.connected_at
  end
end
