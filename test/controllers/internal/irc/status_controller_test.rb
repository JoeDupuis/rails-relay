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
end
