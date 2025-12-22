require "application_system_test_case"

class SidebarConnectionIndicatorTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)

    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/connections")
      .to_return(status: 202, body: "", headers: {})
    stub_request(:delete, %r{#{Rails.configuration.irc_service_url}/internal/irc/connections/\d+})
      .to_return(status: 202, body: "", headers: {})
  end

  test "sidebar indicator updates on connect" do
    server = @user.servers.create!(
      address: "#{@test_id}-sidebar.example.chat",
      nickname: "testnick",
      connected_at: nil
    )

    sign_in_as(@user)
    visit server_path(server)

    within "[data-qa='server-group']" do
      assert_selector ".connection-indicator.-disconnected"
    end

    server.update!(connected_at: Time.current)

    within "[data-qa='server-group']" do
      assert_selector ".connection-indicator.-connected", wait: 5
    end
  end

  test "sidebar indicator updates on disconnect" do
    server = @user.servers.create!(
      address: "#{@test_id}-sidebar2.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )

    sign_in_as(@user)
    visit server_path(server)

    within "[data-qa='server-group']" do
      assert_selector ".connection-indicator.-connected"
    end

    server.mark_disconnected!

    within "[data-qa='server-group']" do
      assert_selector ".connection-indicator.-disconnected", wait: 5
    end
  end
end
