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

  test "GET /internal/irc/status with wrong secret returns 401 unauthorized" do
    get internal_irc_status_path, headers: { "Authorization" => "Bearer wrong_secret" }

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

  test "GET /internal/irc/status returns the IDs of registered connections separately" do
    manager = IrcConnectionManager.instance

    manager.stub :active_connections, [ 1, 2 ] do
      manager.stub :connected_connections, [ 1 ] do
        get internal_irc_status_path, headers: { "Authorization" => "Bearer #{@secret}" }

        json = JSON.parse(response.body)
        assert_equal [ 1, 2 ], json["connections"]
        assert_equal [ 1 ], json["connected"]
      end
    end
  end
end
