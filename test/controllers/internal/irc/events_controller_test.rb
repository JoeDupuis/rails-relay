require "test_helper"

class Internal::Irc::EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @secret = "test_internal_api_secret"
    ENV["INTERNAL_API_SECRET"] = @secret
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)
  end

  test "POST /internal/irc/events with connected event sets connected_at" do
    server = @user.servers.create!(address: "irc-#{@test_id}.example.com", nickname: "testnick")

    post internal_irc_events_path, params: {
      server_id: server.id,
      user_id: @user.id,
      event: { type: "connected" }
    }, headers: { "Authorization" => "Bearer #{@secret}" }, as: :json

    assert_response :ok
    assert_not_nil server.reload.connected_at
  end

  test "POST /internal/irc/events with disconnected event clears connected_at" do
    server = @user.servers.create!(address: "irc-#{@test_id}.example.com", nickname: "testnick", connected_at: Time.current)

    post internal_irc_events_path, params: {
      server_id: server.id,
      user_id: @user.id,
      event: { type: "disconnected" }
    }, headers: { "Authorization" => "Bearer #{@secret}" }, as: :json

    assert_response :ok
    assert_nil server.reload.connected_at
  end

  test "POST /internal/irc/events correctly isolates events to correct user" do
    joe = users(:joe)
    jane = users(:jane)

    joe_server = joe.servers.create!(address: "joe-#{@test_id}.example.com", nickname: "joenick")
    jane_server = jane.servers.create!(address: "jane-#{@test_id}.example.com", nickname: "janenick")

    post internal_irc_events_path, params: {
      server_id: joe_server.id,
      user_id: joe.id,
      event: { type: "connected" }
    }, headers: { "Authorization" => "Bearer #{@secret}" }, as: :json

    assert_response :ok

    assert_not_nil joe_server.reload.connected_at
    assert_nil jane_server.reload.connected_at
  end

  test "POST /internal/irc/events without secret returns 401 unauthorized" do
    post internal_irc_events_path, params: {
      server_id: 1,
      user_id: 1,
      event: { type: "connected" }
    }, as: :json

    assert_response :unauthorized
  end

  test "POST /internal/irc/events with message event creates message" do
    server = @user.servers.create!(address: "irc-#{@test_id}.example.com", nickname: "testnick")

    assert_difference -> { Message.count }, 1 do
      post internal_irc_events_path, params: {
        server_id: server.id,
        user_id: @user.id,
        event: {
          type: "message",
          data: {
            source: "nick!user@host",
            target: "#channel",
            text: "Hello everyone"
          }
        }
      }, headers: { "Authorization" => "Bearer #{@secret}" }, as: :json
    end

    assert_response :ok

    message = Message.last
    assert_equal "nick", message.sender
    assert_equal "Hello everyone", message.content
    assert_equal "privmsg", message.message_type
  end

  test "POST /internal/irc/events with PM creates notification" do
    server = @user.servers.create!(address: "irc-#{@test_id}.example.com", nickname: "testnick")

    assert_difference -> { Notification.count }, 1 do
      post internal_irc_events_path, params: {
        server_id: server.id,
        user_id: @user.id,
        event: {
          type: "message",
          data: {
            source: "john!user@host",
            target: "testnick",
            text: "Private message"
          }
        }
      }, headers: { "Authorization" => "Bearer #{@secret}" }, as: :json
    end

    assert_response :ok

    notification = Notification.last
    assert_equal "dm", notification.reason
    assert_nil notification.message.channel
  end

  test "POST /internal/irc/events with join event creates channel_user" do
    server = @user.servers.create!(address: "irc-#{@test_id}.example.com", nickname: "testnick")
    Channel.create!(server: server, name: "#channel", joined: true)

    assert_difference -> { ChannelUser.count }, 1 do
      post internal_irc_events_path, params: {
        server_id: server.id,
        user_id: @user.id,
        event: {
          type: "join",
          data: {
            source: "newuser!user@host",
            target: "#channel"
          }
        }
      }, headers: { "Authorization" => "Bearer #{@secret}" }, as: :json
    end

    assert_response :ok

    channel = Channel.find_by(name: "#channel")
    assert channel.channel_users.exists?(nickname: "newuser")

    message = Message.last
    assert_equal "join", message.message_type
  end

  test "POST /internal/irc/events with part event removes channel_user" do
    server = @user.servers.create!(address: "irc-#{@test_id}.example.com", nickname: "testnick")
    channel = Channel.create!(server: server, name: "#channel", joined: true)
    channel.channel_users.create!(nickname: "olduser")

    assert_difference -> { ChannelUser.count }, -1 do
      post internal_irc_events_path, params: {
        server_id: server.id,
        user_id: @user.id,
        event: {
          type: "part",
          data: {
            source: "olduser!user@host",
            target: "#channel",
            text: "Leaving"
          }
        }
      }, headers: { "Authorization" => "Bearer #{@secret}" }, as: :json
    end

    assert_response :ok

    message = Message.last
    assert_equal "part", message.message_type
  end

  test "POST /internal/irc/events with topic event updates channel topic" do
    server = @user.servers.create!(address: "irc-#{@test_id}.example.com", nickname: "testnick")
    Channel.create!(server: server, name: "#channel", joined: true)

    post internal_irc_events_path, params: {
      server_id: server.id,
      user_id: @user.id,
      event: {
        type: "topic",
        data: {
          source: "op!user@host",
          target: "#channel",
          text: "New topic here"
        }
      }
    }, headers: { "Authorization" => "Bearer #{@secret}" }, as: :json

    assert_response :ok

    channel = Channel.find_by(name: "#channel")
    assert_equal "New topic here", channel.topic

    message = Message.last
    assert_equal "topic", message.message_type
  end

  test "POST /internal/irc/events with names event creates channel_users with modes" do
    server = @user.servers.create!(address: "irc-#{@test_id}.example.com", nickname: "testnick")
    Channel.create!(server: server, name: "#channel", joined: true)

    post internal_irc_events_path, params: {
      server_id: server.id,
      user_id: @user.id,
      event: {
        type: "names",
        data: {
          channel: "#channel",
          names: [ "@opuser", "+voiceuser", "regularuser" ]
        }
      }
    }, headers: { "Authorization" => "Bearer #{@secret}" }, as: :json

    assert_response :ok

    channel = Channel.find_by(name: "#channel")
    assert_equal 3, channel.channel_users.count

    op = channel.channel_users.find_by(nickname: "opuser")
    assert op.op?

    voice = channel.channel_users.find_by(nickname: "voiceuser")
    assert voice.voiced?

    regular = channel.channel_users.find_by(nickname: "regularuser")
    assert_not regular.op?
    assert_not regular.voiced?
  end
end
