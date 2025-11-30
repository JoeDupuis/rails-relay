require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "GET /passwords/new renders password reset request form" do
    get new_password_path

    assert_response :ok
    assert_select "input[name='email_address']"
    assert_select "input[type='submit']"
  end

  test "POST /passwords with valid email enqueues reset email and redirects" do
    user = users(:joe)

    assert_enqueued_email_with PasswordsMailer, :reset, args: [ user ] do
      post passwords_path, params: { email_address: user.email_address }
    end

    assert_redirected_to new_session_path
    assert_match "Password reset instructions sent", flash[:notice]
  end

  test "POST /passwords with invalid email still shows success message" do
    post passwords_path, params: { email_address: "nonexistent@example.com" }

    assert_redirected_to new_session_path
    assert_match "Password reset instructions sent", flash[:notice]
  end

  test "GET /passwords/:token/edit with valid token renders password reset form" do
    user = users(:joe)
    token = user.password_reset_token

    get edit_password_path(token)

    assert_response :ok
    assert_select "input[name='password']"
    assert_select "input[name='password_confirmation']"
  end

  test "GET /passwords/:token/edit with invalid token redirects with error" do
    get edit_password_path("invalidtoken")

    assert_redirected_to new_password_path
    assert_match "invalid or has expired", flash[:alert]
  end

  test "PATCH /passwords/:token with valid passwords resets password and destroys sessions" do
    user = users(:joe)
    token = user.password_reset_token
    post session_path, params: { email_address: user.email_address, password: "password123" }
    session_count_before = user.sessions.count
    assert session_count_before > 0

    patch password_path(token), params: { password: "newpassword123", password_confirmation: "newpassword123" }

    assert_redirected_to new_session_path
    assert_match "Password has been reset", flash[:notice]
    assert user.reload.authenticate("newpassword123")
    assert_equal 0, user.sessions.count
  end

  test "PATCH /passwords/:token with mismatched passwords shows error" do
    user = users(:joe)
    token = user.password_reset_token

    patch password_path(token), params: { password: "newpassword123", password_confirmation: "different" }

    assert_redirected_to edit_password_path(token)
    assert_match "Passwords did not match", flash[:alert]
  end
end
