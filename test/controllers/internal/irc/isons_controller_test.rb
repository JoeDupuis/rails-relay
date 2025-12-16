require "test_helper"

class MockIrcConnectionForIson
  attr_accessor :ison_response

  def initialize(**)
    @ison_response = []
  end

  def start = nil
  def stop = nil
  def execute(command, params) = nil

  def ison(nicks)
    @ison_response
  end
end

class Internal::Irc::IsonsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @secret = "test_internal_api_secret"
    ENV["INTERNAL_API_SECRET"] = @secret
    @server_id = rand(10000..99999)
    @mock_connection = MockIrcConnectionForIson.new
    IrcConnectionManager.instance.reset!
  end

  teardown do
    IrcConnectionManager.instance.reset!
  end

  test "GET /internal/irc/ison returns online nicks" do
    @mock_connection.ison_response = [ "alice", "charlie" ]

    IrcConnection.stub :new, @mock_connection do
      IrcConnectionManager.instance.start(server_id: @server_id, user_id: 1, config: {})

      get internal_irc_ison_path, params: {
        server_id: @server_id,
        nicks: [ "alice", "bob", "charlie" ]
      }, headers: { "Authorization" => "Bearer #{@secret}" }

      assert_response :ok
      json = JSON.parse(response.body)
      assert_equal [ "alice", "charlie" ], json["online"]
    end
  end

  test "GET /internal/irc/ison returns empty array when no nicks online" do
    @mock_connection.ison_response = []

    IrcConnection.stub :new, @mock_connection do
      IrcConnectionManager.instance.start(server_id: @server_id, user_id: 1, config: {})

      get internal_irc_ison_path, params: {
        server_id: @server_id,
        nicks: [ "alice", "bob" ]
      }, headers: { "Authorization" => "Bearer #{@secret}" }

      assert_response :ok
      json = JSON.parse(response.body)
      assert_equal [], json["online"]
    end
  end

  test "GET /internal/irc/ison with no connection returns 404" do
    get internal_irc_ison_path, params: {
      server_id: 999999,
      nicks: [ "alice" ]
    }, headers: { "Authorization" => "Bearer #{@secret}" }

    assert_response :not_found
  end

  test "GET /internal/irc/ison without secret returns 401" do
    IrcConnection.stub :new, @mock_connection do
      IrcConnectionManager.instance.start(server_id: @server_id, user_id: 1, config: {})

      get internal_irc_ison_path, params: {
        server_id: @server_id,
        nicks: [ "alice" ]
      }

      assert_response :unauthorized
    end
  end
end
