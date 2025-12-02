require "test_helper"

class Internal::Irc::StatusControllerTest < ActionDispatch::IntegrationTest
  setup do
    @secret = "test_internal_api_secret"
    ENV["INTERNAL_API_SECRET"] = @secret
  end

  test "GET /internal/irc/status returns JSON with status and connections array" do
    get internal_irc_status_path, headers: { "Authorization" => "Bearer #{@secret}" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "ok", json["status"]
    assert_kind_of Array, json["connections"]
  end

  test "GET /internal/irc/status without secret returns 401 unauthorized" do
    get internal_irc_status_path

    assert_response :unauthorized
  end

  test "GET /internal/irc/status returns connected server IDs" do
    user = users(:joe)
    server1 = user.servers.create!(address: "irc1.example.com", nickname: "testnick")
    server2 = user.servers.create!(address: "irc2.example.com", nickname: "testnick2")

    IrcConnectionManager.instance.stub :active_connections, [ server1.id, server2.id ] do
      get internal_irc_status_path, headers: { "Authorization" => "Bearer #{@secret}" }

      assert_response :ok
      json = JSON.parse(response.body)
      assert_includes json["connections"], server1.id
      assert_includes json["connections"], server2.id
    end
  end
end
