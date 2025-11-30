require "test_helper"

class Internal::Irc::ConnectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @secret = "test_internal_api_secret"
    ENV["INTERNAL_API_SECRET"] = @secret
  end

  test "POST /internal/irc/connections with valid secret returns 202 accepted" do
    post internal_irc_connections_path, params: {
      server_id: 1,
      user_id: 1,
      config: { address: "irc.example.com", port: 6697, ssl: true, nickname: "testnick" }
    }, headers: { "Authorization" => "Bearer #{@secret}" }, as: :json

    assert_response :accepted
  end

  test "POST /internal/irc/connections without secret returns 401 unauthorized" do
    post internal_irc_connections_path, params: {
      server_id: 1,
      user_id: 1,
      config: { address: "irc.example.com" }
    }, as: :json

    assert_response :unauthorized
  end

  test "POST /internal/irc/connections with wrong secret returns 401 unauthorized" do
    post internal_irc_connections_path, params: {
      server_id: 1,
      user_id: 1,
      config: { address: "irc.example.com" }
    }, headers: { "Authorization" => "Bearer wrong_secret" }, as: :json

    assert_response :unauthorized
  end

  test "DELETE /internal/irc/connections/:id returns 200 ok" do
    delete internal_irc_connection_path(99), headers: { "Authorization" => "Bearer #{@secret}" }

    assert_response :ok
  end
end
