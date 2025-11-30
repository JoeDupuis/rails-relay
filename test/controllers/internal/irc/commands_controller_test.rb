require "test_helper"

class Internal::Irc::CommandsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @secret = "test_internal_api_secret"
    ENV["INTERNAL_API_SECRET"] = @secret
    @server_id = rand(10000..99999)
    IrcConnectionManager.instance.start(server_id: @server_id, user_id: 1, config: {})
  end

  teardown do
    IrcConnectionManager.instance.stop(@server_id)
  end

  test "POST /internal/irc/commands with active connection returns 202 accepted" do
    post internal_irc_commands_path, params: {
      server_id: @server_id,
      command: "privmsg",
      params: { target: "#ruby", message: "Hello!" }
    }, headers: { "Authorization" => "Bearer #{@secret}" }, as: :json

    assert_response :accepted
  end

  test "POST /internal/irc/commands with no connection returns 404 not found" do
    post internal_irc_commands_path, params: {
      server_id: 999999,
      command: "privmsg",
      params: { target: "#ruby", message: "Hello!" }
    }, headers: { "Authorization" => "Bearer #{@secret}" }, as: :json

    assert_response :not_found
  end

  test "POST /internal/irc/commands without secret returns 401 unauthorized" do
    post internal_irc_commands_path, params: {
      server_id: @server_id,
      command: "privmsg",
      params: { target: "#ruby", message: "Hello!" }
    }, as: :json

    assert_response :unauthorized
  end
end
