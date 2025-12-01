require "application_system_test_case"

class ServerFormTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
  end

  def sign_in_and_visit_new_server
    visit new_session_path
    fill_in "email_address", with: @user.email_address
    fill_in "password", with: "password123"
    click_button "Sign in"
    assert_no_selector "input[id='password']", wait: 5
    visit new_server_path
    assert_selector "input[id='server_address']"
  end

  test "SSL verify checkbox is visible when SSL is checked" do
    sign_in_and_visit_new_server

    ssl_checkbox = find("#server_ssl")
    ssl_verify_div = find("[data-ssl-target='verifyField']")

    assert ssl_checkbox.checked?
    assert ssl_verify_div.visible?
  end

  test "SSL verify checkbox is hidden when SSL is unchecked" do
    sign_in_and_visit_new_server

    find("#server_ssl").uncheck
    ssl_verify_div = find("[data-ssl-target='verifyField']", visible: :all)
    assert_not ssl_verify_div.visible?
  end

  test "SSL verify checkbox appears when SSL is re-checked" do
    sign_in_and_visit_new_server

    find("#server_ssl").uncheck
    ssl_verify_div = find("[data-ssl-target='verifyField']", visible: :all)
    assert_not ssl_verify_div.visible?

    find("#server_ssl").check
    assert ssl_verify_div.visible?
  end
end
