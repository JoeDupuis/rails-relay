require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "GET /session/new renders login form" do
    get new_session_path

    assert_response :ok
    assert_select "input[name='email_address']"
    assert_select "input[name='password']"
    assert_select "input[type='submit'][value='Sign in']"
  end

  test "POST /session with valid credentials creates session and redirects to root" do
    user = users(:joe)

    assert_difference "Session.count", 1 do
      post session_path, params: { email_address: user.email_address, password: "password123" }
    end

    assert_redirected_to root_path
    assert cookies[:session_id].present?
  end

  test "POST /session with invalid email returns 422 and re-renders form" do
    post session_path, params: { email_address: "wrong@example.com", password: "password123" }

    assert_response :unprocessable_entity
    assert_select "input[name='email_address']"
    assert_match "Invalid email or password", response.body
  end

  test "POST /session with invalid password returns 422 and re-renders form" do
    user = users(:joe)

    post session_path, params: { email_address: user.email_address, password: "wrongpassword" }

    assert_response :unprocessable_entity
    assert_select "input[name='email_address']"
    assert_match "Invalid email or password", response.body
  end

  test "DELETE /session destroys session and redirects to login" do
    user = users(:joe)
    post session_path, params: { email_address: user.email_address, password: "password123" }
    session_record = Session.last

    delete session_path

    assert_redirected_to new_session_path
    assert_nil Session.find_by(id: session_record.id)
  end
end
