require "test_helper"

class MockIrcConnection
  def initialize(**) = nil
  def start = nil
  def stop = nil
  def execute(command, params) = nil
end

class Internal::Irc::ConnectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @secret = "test_internal_api_secret"
    ENV["INTERNAL_API_SECRET"] = @secret
    IrcConnectionManager.instance.reset!
  end

  test "POST /internal/irc/connections with valid secret returns 202 accepted" do
    IrcConnection.stub :new, MockIrcConnection.new do
      post internal_irc_connections_path, params: {
        server_id: 1,
        user_id: 1,
        config: { address: "irc.example.com", port: 6697, ssl: true, nickname: "testnick" }
      }, headers: { "Authorization" => "Bearer #{@secret}" }, as: :json

      assert_response :accepted
    end
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
