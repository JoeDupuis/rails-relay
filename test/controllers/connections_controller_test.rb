require "test_helper"
require "webmock/minitest"

class ConnectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    @test_id = SecureRandom.hex(4)

    TenantRecord.with_tenant(@user.id.to_s) do
      @server = Server.create!(
        address: "irc-#{@test_id}.example.com",
        port: 6697,
        ssl: true,
        nickname: "testnick"
      )
    end
  end

  test "POST /servers/:id/connection calls InternalApiClient with correct params" do
    stub_request(:post, "http://localhost:3000/internal/irc/connections")
      .with(
        body: hash_including(
          "server_id" => @server.id,
          "user_id" => @user.id,
          "config" => hash_including(
            "address" => @server.address,
            "port" => @server.port,
            "ssl" => @server.ssl,
            "nickname" => @server.nickname
          )
        ),
        headers: { "Authorization" => /Bearer .+/ }
      )
      .to_return(status: 201, body: "{}", headers: { "Content-Type" => "application/json" })

    post server_connection_path(@server)
    assert_redirected_to server_path(@server)
    assert_equal "Connecting...", flash[:notice]
  end

  test "POST /servers/:id/connection handles service unavailable" do
    stub_request(:post, "http://localhost:3000/internal/irc/connections")
      .to_raise(Errno::ECONNREFUSED)

    post server_connection_path(@server)
    assert_redirected_to server_path(@server)
    assert_equal "IRC service unavailable", flash[:alert]
  end

  test "DELETE /servers/:id/connection calls InternalApiClient" do
    stub_request(:delete, "http://localhost:3000/internal/irc/connections/#{@server.id}")
      .with(headers: { "Authorization" => /Bearer .+/ })
      .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

    delete server_connection_path(@server)
    assert_redirected_to server_path(@server)
    assert_equal "Disconnecting...", flash[:notice]
  end

  test "DELETE /servers/:id/connection handles service unavailable" do
    stub_request(:delete, "http://localhost:3000/internal/irc/connections/#{@server.id}")
      .to_raise(Errno::ECONNREFUSED)

    delete server_connection_path(@server)
    assert_redirected_to server_path(@server)
    assert_equal "IRC service unavailable", flash[:alert]
  end
end
