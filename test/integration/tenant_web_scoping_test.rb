require "test_helper"

class TenantWebScopingTest < ActionDispatch::IntegrationTest
  test "authenticated user only sees their data" do
    user_a = users(:joe)
    user_b = users(:jane)

    post session_path, params: { email_address: user_a.email_address, password: "password123" }
    post servers_path, params: { server: { address: "irc.libera.chat", nickname: "userA" } }
    assert_redirected_to servers_path
    delete session_path

    post session_path, params: { email_address: user_b.email_address, password: "secret456" }
    get servers_path
    assert_response :ok
    assert_no_match "irc.libera.chat", response.body
  end
end
