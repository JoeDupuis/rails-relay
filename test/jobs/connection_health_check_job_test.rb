require "test_helper"
require "webmock/minitest"

class ConnectionHealthCheckJobTest < ActiveSupport::TestCase
  setup do
    @user = users(:joe)
    @server = @user.servers.create!(address: "irc.example.com", nickname: "testnick", connected_at: Time.current)
    @channel = @server.channels.create!(name: "#ruby", joined: true)
    @channel.channel_users.create!(nickname: "some_user")

    WebMock.stub_request(:get, %r{/internal/irc/status})
      .to_return(status: 200, body: { status: "ok", connections: [] }.to_json, headers: { "Content-Type" => "application/json" })
  end

  test "marks stale connections as disconnected" do
    assert @server.connected?
    assert @channel.joined?
    assert @channel.channel_users.any?

    ConnectionHealthCheckJob.perform_now

    @server.reload
    @channel.reload

    assert_nil @server.connected_at
    assert_not @channel.joined?
    assert_empty @channel.channel_users
  end

  test "keeps valid connections connected" do
    WebMock.stub_request(:get, %r{/internal/irc/status})
      .to_return(status: 200, body: { status: "ok", connections: [ @server.id ] }.to_json, headers: { "Content-Type" => "application/json" })

    original_connected_at = @server.connected_at

    ConnectionHealthCheckJob.perform_now

    @server.reload
    assert_equal original_connected_at.to_i, @server.connected_at.to_i
    assert @channel.reload.joined?
  end

  test "handles IRC service unavailable by marking all servers disconnected" do
    other_server = @user.servers.create!(
      address: "other.irc.example.com",
      nickname: "TestNick",
      connected_at: Time.current
    )

    WebMock.stub_request(:get, %r{/internal/irc/status})
      .to_raise(InternalApiClient::ServiceUnavailable.new("Service unavailable"))

    ConnectionHealthCheckJob.perform_now

    assert_nil @server.reload.connected_at
    assert_nil other_server.reload.connected_at
  end

  test "does nothing when no servers are connected" do
    @server.update!(connected_at: nil)

    WebMock.reset!
    stub = WebMock.stub_request(:get, %r{/internal/irc/status})
      .to_return(status: 200, body: { status: "ok", connections: [] }.to_json, headers: { "Content-Type" => "application/json" })

    ConnectionHealthCheckJob.perform_now

    assert_not_requested stub
  end
end
