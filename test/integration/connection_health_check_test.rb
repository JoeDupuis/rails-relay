require "test_helper"
require "webmock/minitest"

class ConnectionHealthCheckTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
    @server = @user.servers.create!(address: "irc.example.com", nickname: "testnick", connected_at: Time.current)
    @channel = @server.channels.create!(name: "#ruby", joined: true)
    @channel.channel_users.create!(nickname: "some_user")

    WebMock.stub_request(:get, %r{/internal/irc/status})
      .to_return(status: 200, body: { status: "ok", connections: [] }.to_json, headers: { "Content-Type" => "application/json" })
  end

  test "stale connection detected on health check resets server and channels" do
    assert @server.connected?
    assert @channel.joined?
    assert @channel.channel_users.any?

    ConnectionHealthCheckJob.perform_now

    @server.reload
    @channel.reload

    assert_not @server.connected?
    assert_not @channel.joined?
    assert_empty @channel.channel_users
  end
end
