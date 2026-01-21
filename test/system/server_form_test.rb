require "application_system_test_case"

class ServerFormTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
  end

  def sign_in_and_visit_new_server
    sign_in_as(@user)
    visit new_server_path
    assert_selector "input[id='server_address']"
  end

  test "SSL verify checkbox is visible when SSL is checked" do
    sign_in_and_visit_new_server

    assert find("#server_ssl").checked?
    assert_selector "[data-ssl-target='verifyField']", visible: true
  end

  test "SSL verify checkbox is hidden when SSL is unchecked" do
    sign_in_and_visit_new_server

    find("#server_ssl").uncheck

    assert_selector "[data-ssl-target='verifyField']", visible: false, wait: 2
  end

  test "SSL verify checkbox appears when SSL is re-checked" do
    sign_in_and_visit_new_server

    find("#server_ssl").uncheck
    assert_selector "[data-ssl-target='verifyField']", visible: false, wait: 2

    find("#server_ssl").check
    assert_selector "[data-ssl-target='verifyField']", visible: true, wait: 2
  end
end
