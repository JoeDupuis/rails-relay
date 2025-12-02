require "test_helper"
require "webmock/minitest"

class RealtimeChannelStatusTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    @test_id = SecureRandom.hex(4)

    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_return(status: 202, body: "", headers: {})
  end

  def unique_address(base = "irc.example")
    "#{base}-#{@test_id}.chat"
  end

  def create_connected_server
    @user.servers.create!(address: unique_address, nickname: "testnick", connected_at: Time.current)
  end

  test "channel view updates when kicked via IrcEventHandler" do
    server = create_connected_server
    channel = Channel.create!(server: server, name: "#ruby", joined: true)
    channel.channel_users.create!(nickname: "testnick")

    get channel_path(channel)
    assert_response :ok
    assert_select "button.leave", text: "Leave"
    assert_no_match(/not in this channel/i, response.body)

    assert_turbo_stream_broadcasts channel do
      post internal_irc_events_path, params: {
        server_id: server.id,
        user_id: @user.id,
        event: {
          type: "kick",
          data: {
            source: "op!op@host",
            target: "#ruby",
            kicked: "testnick",
            text: "Goodbye"
          }
        }
      }, headers: { "Authorization" => "Bearer #{ENV['INTERNAL_API_SECRET']}" }
    end
  end

  test "channel view updates when force-joined via IrcEventHandler" do
    server = create_connected_server
    channel = Channel.create!(server: server, name: "#ruby", joined: false)

    get channel_path(channel)
    assert_response :ok
    assert_select "input[value='Join']"
    assert_match(/not in this channel/i, response.body)

    assert_turbo_stream_broadcasts channel do
      post internal_irc_events_path, params: {
        server_id: server.id,
        user_id: @user.id,
        event: {
          type: "join",
          data: {
            source: "testnick!user@host",
            target: "#ruby"
          }
        }
      }, headers: { "Authorization" => "Bearer #{ENV['INTERNAL_API_SECRET']}" }
    end
  end

  test "server page updates channel list when joined via IrcEventHandler" do
    server = create_connected_server
    channel = Channel.create!(server: server, name: "#ruby", joined: false)

    get server_path(server)
    assert_response :ok
    assert_match(/\(not joined\)/i, response.body)
    assert_select "form input[value='Join']"

    assert_turbo_stream_broadcasts server do
      post internal_irc_events_path, params: {
        server_id: server.id,
        user_id: @user.id,
        event: {
          type: "join",
          data: {
            source: "testnick!user@host",
            target: "#ruby"
          }
        }
      }, headers: { "Authorization" => "Bearer #{ENV['INTERNAL_API_SECRET']}" }
    end
  end

  test "server page updates channel list when kicked via IrcEventHandler" do
    server = create_connected_server
    channel = Channel.create!(server: server, name: "#ruby", joined: true)
    channel.channel_users.create!(nickname: "testnick")

    get server_path(server)
    assert_response :ok
    assert_no_match(/\(not joined\)/i, response.body)
    assert_select "a.link", text: "View"
    assert_select "button.link.-danger", text: "Leave"

    assert_turbo_stream_broadcasts server do
      post internal_irc_events_path, params: {
        server_id: server.id,
        user_id: @user.id,
        event: {
          type: "kick",
          data: {
            source: "op!op@host",
            target: "#ruby",
            kicked: "testnick",
            text: "Bye"
          }
        }
      }, headers: { "Authorization" => "Bearer #{ENV['INTERNAL_API_SECRET']}" }
    end
  end
end
