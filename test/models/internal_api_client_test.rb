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

  test "send_command returns parts array on 202" do
    stub_request(:post, "http://localhost:3000/internal/irc/commands")
      .to_return(status: 202, body: { parts: [ "Hello" ] }.to_json, headers: { "Content-Type" => "application/json" })

    result = InternalApiClient.send_command(
      server_id: 1,
      command: "privmsg",
      params: { target: "#ruby", message: "Hello" }
    )

    assert_equal [ "Hello" ], result
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

  test "ison sends GET with query params and returns online nicks" do
    params = [ [ "server_id", 42 ] ] + [ "alice", "bob" ].map { |n| [ "nicks[]", n ] }
    query = URI.encode_www_form(params)
    stub_request(:get, "http://localhost:3000/internal/irc/ison?#{query}")
      .with(headers: { "Authorization" => "Bearer #{@secret}" })
      .to_return(status: 200, body: { online: [ "alice" ] }.to_json)

    result = InternalApiClient.ison(server_id: 42, nicks: [ "alice", "bob" ])

    assert_equal [ "alice" ], result
  end

  test "ison returns nil on 404" do
    params = [ [ "server_id", 99 ] ] + [ "alice" ].map { |n| [ "nicks[]", n ] }
    query = URI.encode_www_form(params)
    stub_request(:get, "http://localhost:3000/internal/irc/ison?#{query}")
      .to_return(status: 404)

    result = InternalApiClient.ison(server_id: 99, nicks: [ "alice" ])

    assert_nil result
  end
end
