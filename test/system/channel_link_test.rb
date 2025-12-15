require "application_system_test_case"

class ChannelLinkTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)
    stub_request(:any, /#{Rails.configuration.irc_service_url}/)
      .to_return(status: 202, body: "", headers: {})
  end

  def unique_address(base = "irc.example")
    "#{base}-#{@test_id}.chat"
  end

  def sign_in_and_visit_server(server)
    sign_in_as(@user)
    visit server_path(server)
    assert_selector ".server-view"
  end

  test "clicking channel name navigates to channel view" do
    server = @user.servers.create!(address: unique_address("chanclick"), nickname: "testnick", connected_at: Time.current)
    channel = Channel.create!(server: server, name: "#ruby", joined: true)

    sign_in_and_visit_server(server)

    assert_selector ".server-view .channels .row a.name", text: "#ruby"
    find(".server-view .channels .row a.name", text: "#ruby").click

    assert_current_path channel_path(channel)
    assert_selector ".channel-view"
  end
end
