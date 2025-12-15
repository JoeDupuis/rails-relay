require "application_system_test_case"

class FlashDismissTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)

    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/connections")
      .to_return(status: 202, body: "", headers: {})
    stub_request(:delete, %r{#{Rails.configuration.irc_service_url}/internal/irc/connections/\d+})
      .to_return(status: 202, body: "", headers: {})
  end

  test "connecting flash disappears after connection completes" do
    server = @user.servers.create!(
      address: "#{@test_id}-flash.example.chat",
      nickname: "testnick",
      connected_at: nil
    )

    sign_in_as(@user)
    visit server_path(server)

    click_button "Connect"

    assert_selector ".notice", text: "Connecting..."
    assert_selector ".indicator.-disconnected"

    server.update!(connected_at: Time.current)

    assert_no_selector ".notice", text: "Connecting...", wait: 5
    assert_selector ".indicator.-connected"
  end
end
