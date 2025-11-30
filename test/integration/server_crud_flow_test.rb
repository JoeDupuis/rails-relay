require "test_helper"

class ServerCrudFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    @test_id = SecureRandom.hex(4)
  end

  def unique_address(base = "irc.example")
    "#{base}-#{@test_id}.chat"
  end

  test "User adds a server" do
    address = unique_address("libera")

    get new_server_path
    assert_response :ok

    post servers_path, params: {
      server: { address: address, nickname: "testnick" }
    }

    server = TenantRecord.with_tenant(@user.id.to_s) { Server.last }
    assert_redirected_to server_path(server)

    follow_redirect!
    assert_response :ok
    assert_match address, response.body

    TenantRecord.with_tenant(@user.id.to_s) do
      assert Server.find_by(address: address).present?
    end
  end

  test "User edits a server" do
    address = unique_address("efnet")
    post servers_path, params: { server: { address: address, nickname: "oldnick" } }
    server = TenantRecord.with_tenant(@user.id.to_s) { Server.last }

    get edit_server_path(server)
    assert_response :ok

    patch server_path(server), params: { server: { nickname: "newnick" } }
    assert_redirected_to server_path(server)

    follow_redirect!
    assert_response :ok
    assert_match "newnick", response.body

    TenantRecord.with_tenant(@user.id.to_s) do
      assert_equal "newnick", server.reload.nickname
    end
  end

  test "User deletes a server" do
    address = unique_address("freenode")
    post servers_path, params: { server: { address: address, nickname: "testnick" } }
    server = TenantRecord.with_tenant(@user.id.to_s) { Server.last }

    get server_path(server)
    assert_response :ok

    delete server_path(server)
    assert_redirected_to servers_path

    follow_redirect!
    assert_response :ok
    assert_no_match address, response.body

    TenantRecord.with_tenant(@user.id.to_s) do
      assert_nil Server.find_by(address: address)
    end
  end
end
