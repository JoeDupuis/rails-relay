require "test_helper"

class AccessControlTest < ActionDispatch::IntegrationTest
  test "unauthenticated user visiting protected page is redirected to login" do
    get root_path

    assert_redirected_to new_session_path
  end

  test "authenticated user can visit protected page" do
    user = users(:joe)
    post session_path, params: { email_address: user.email_address, password: "password123" }

    get root_path

    assert_response :ok
  end

  test "redirect back to originally requested page after sign in" do
    get root_path
    assert_redirected_to new_session_path

    user = users(:joe)
    post session_path, params: { email_address: user.email_address, password: "password123" }

    assert_redirected_to root_url
  end
end
