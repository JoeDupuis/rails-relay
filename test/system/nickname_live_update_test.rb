require "application_system_test_case"

class NicknameLiveUpdateTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)
  end

  def sign_in_user
    visit new_session_path
    fill_in "email_address", with: @user.email_address
    fill_in "password", with: "password123"
    click_button "Sign in"
    assert_no_selector "input[id='password']", wait: 5
  end

  test "nickname updates in real-time on server page" do
    server = @user.servers.create!(
      address: "#{@test_id}-nick.example.chat",
      nickname: "oldnick",
      connected_at: Time.current
    )

    sign_in_user
    visit server_path(server)

    assert_selector ".nickname strong", text: "oldnick"

    server.update!(nickname: "newnick")

    assert_selector ".nickname strong", text: "newnick", wait: 5
  end
end
