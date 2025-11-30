require "test_helper"
require "webmock/minitest"

class InternalApiClientTest < ActiveSupport::TestCase
  setup do
    @secret = "test_internal_api_secret"
    ENV["INTERNAL_API_SECRET"] = @secret
  end

  test "start_connection posts to IRC service" do
    stub_request(:post, "http://localhost:3000/internal/irc/connections")
      .with(
        headers: { "Authorization" => "Bearer #{@secret}", "Content-Type" => "application/json" },
        body: { server_id: 1, user_id: 2, config: { address: "irc.example.com" } }.to_json
      )
      .to_return(status: 202)

    response = InternalApiClient.start_connection(
      server_id: 1,
      user_id: 2,
      config: { address: "irc.example.com" }
    )

    assert_equal "202", response.code
  end

  test "stop_connection sends DELETE to IRC service" do
    stub_request(:delete, "http://localhost:3000/internal/irc/connections/42")
      .with(headers: { "Authorization" => "Bearer #{@secret}" })
      .to_return(status: 200)

    response = InternalApiClient.stop_connection(server_id: 42)

    assert_equal "200", response.code
  end

  test "send_command returns true on 202" do
    stub_request(:post, "http://localhost:3000/internal/irc/commands")
      .to_return(status: 202)

    result = InternalApiClient.send_command(
      server_id: 1,
      command: "privmsg",
      params: { target: "#ruby", message: "Hello" }
    )

    assert result
  end

  test "send_command raises ConnectionNotFound on 404" do
    stub_request(:post, "http://localhost:3000/internal/irc/commands")
      .to_return(status: 404)

    assert_raises InternalApiClient::ConnectionNotFound do
      InternalApiClient.send_command(
        server_id: 999,
        command: "privmsg",
        params: { target: "#ruby", message: "Hello" }
      )
    end
  end

  test "send_command raises ServiceUnavailable on other errors" do
    stub_request(:post, "http://localhost:3000/internal/irc/commands")
      .to_return(status: 500)

    assert_raises InternalApiClient::ServiceUnavailable do
      InternalApiClient.send_command(
        server_id: 1,
        command: "privmsg",
        params: { target: "#ruby", message: "Hello" }
      )
    end
  end

  test "send_command raises ServiceUnavailable on network error" do
    stub_request(:post, "http://localhost:3000/internal/irc/commands")
      .to_raise(Errno::ECONNREFUSED)

    assert_raises InternalApiClient::ServiceUnavailable do
      InternalApiClient.send_command(
        server_id: 1,
        command: "privmsg",
        params: { target: "#ruby", message: "Hello" }
      )
    end
  end

  test "post_event posts to web service" do
    stub_request(:post, "http://localhost:3000/internal/irc/events")
      .with(
        headers: { "Authorization" => "Bearer #{@secret}", "Content-Type" => "application/json" },
        body: { server_id: 1, user_id: 2, event: { type: "message" } }.to_json
      )
      .to_return(status: 200)

    response = InternalApiClient.post_event(
      server_id: 1,
      user_id: 2,
      event: { type: "message" }
    )

    assert_equal "200", response.code
  end

  test "status gets from IRC service" do
    stub_request(:get, "http://localhost:3000/internal/irc/status")
      .with(headers: { "Authorization" => "Bearer #{@secret}" })
      .to_return(status: 200, body: { status: "ok", connections: [ 1, 2, 3 ] }.to_json)

    response = InternalApiClient.status

    assert_equal "200", response.code
    json = JSON.parse(response.body)
    assert_equal "ok", json["status"]
    assert_equal [ 1, 2, 3 ], json["connections"]
  end
end
