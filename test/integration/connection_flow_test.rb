require "test_helper"
require "webmock/minitest"

class ConnectionFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    @test_id = SecureRandom.hex(4)

    @server = @user.servers.create!(
      address: "irc-#{@test_id}.example.com",
      port: 6697,
      ssl: true,
      nickname: "testnick"
    )
  end

  test "user connects to server via POST to connection" do
    stub_request(:post, "http://localhost:3000/internal/irc/connections")
      .to_return(status: 201, body: "{}", headers: { "Content-Type" => "application/json" })

    post server_connection_path(@server)
    assert_redirected_to server_path(@server)
    follow_redirect!
    assert_response :ok
  end

  test "user disconnects from server via DELETE to connection" do
    stub_request(:delete, "http://localhost:3000/internal/irc/connections/#{@server.id}")
      .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

    delete server_connection_path(@server)
    assert_redirected_to server_path(@server)
    follow_redirect!
    assert_response :ok
  end
end
