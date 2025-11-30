require "test_helper"

class Internal::Irc::EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @secret = "test_internal_api_secret"
    ENV["INTERNAL_API_SECRET"] = @secret
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)
  end

  test "POST /internal/irc/events with connected event sets connected_at" do
    server = TenantRecord.with_tenant(@user.id.to_s) do
      Server.create!(address: "irc-#{@test_id}.example.com", nickname: "testnick")
    end

    post internal_irc_events_path, params: {
      server_id: server.id,
      user_id: @user.id,
      event: { type: "connected" }
    }, headers: { "Authorization" => "Bearer #{@secret}" }, as: :json

    assert_response :ok
    TenantRecord.with_tenant(@user.id.to_s) do
      assert_not_nil server.reload.connected_at
    end
  end

  test "POST /internal/irc/events with disconnected event clears connected_at" do
    server = TenantRecord.with_tenant(@user.id.to_s) do
      Server.create!(address: "irc-#{@test_id}.example.com", nickname: "testnick", connected_at: Time.current)
    end

    post internal_irc_events_path, params: {
      server_id: server.id,
      user_id: @user.id,
      event: { type: "disconnected" }
    }, headers: { "Authorization" => "Bearer #{@secret}" }, as: :json

    assert_response :ok
    TenantRecord.with_tenant(@user.id.to_s) do
      assert_nil server.reload.connected_at
    end
  end

  test "POST /internal/irc/events switches tenant correctly" do
    joe = users(:joe)
    jane = users(:jane)

    joe_server = TenantRecord.with_tenant(joe.id.to_s) do
      Server.create!(address: "joe-#{@test_id}.example.com", nickname: "joenick")
    end

    jane_server = TenantRecord.with_tenant(jane.id.to_s) do
      Server.create!(address: "jane-#{@test_id}.example.com", nickname: "janenick")
    end

    post internal_irc_events_path, params: {
      server_id: joe_server.id,
      user_id: joe.id,
      event: { type: "connected" }
    }, headers: { "Authorization" => "Bearer #{@secret}" }, as: :json

    assert_response :ok

    TenantRecord.with_tenant(joe.id.to_s) do
      assert_not_nil joe_server.reload.connected_at
    end

    TenantRecord.with_tenant(jane.id.to_s) do
      assert_nil jane_server.reload.connected_at
    end
  end

  test "POST /internal/irc/events without secret returns 401 unauthorized" do
    post internal_irc_events_path, params: {
      server_id: 1,
      user_id: 1,
      event: { type: "connected" }
    }, as: :json

    assert_response :unauthorized
  end
end
