require "application_system_test_case"

class FileUploadTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)
    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_return(status: 202, body: { success: true }.to_json)
  end

  def create_connected_channel
    server = @user.servers.create!(
      address: "#{@test_id}-irc.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    Channel.create!(server: server, name: "#uploads", joined: true)
  end

  test "sender sees file upload message content immediately without refresh" do
    channel = create_connected_channel
    sign_in_as(@user)
    visit channel_path(channel)

    assert_selector ".message-input"

    file_path = file_fixture("test.png")
    find("input[name='message[file]']", visible: false).attach_file(file_path)

    assert_selector ".message-item", wait: 5

    within ".message-item" do
      assert_selector ".content", text: /active_storage/
    end
  end

  test "text message after image upload sends text not image link" do
    channel = create_connected_channel
    sign_in_as(@user)
    visit channel_path(channel)

    assert_selector ".message-input"

    file_path = file_fixture("test.png")
    find("input[name='message[file]']", visible: false).attach_file(file_path)

    assert_selector ".message-item", wait: 5
    within first(".message-item") do
      assert_selector ".content", text: /active_storage/
    end

    fill_in "Message #uploads", with: "lol"
    click_button "Send"

    assert_selector ".message-item", count: 2, wait: 5

    within all(".message-item").last do
      assert_selector ".content", text: "lol"
      assert_no_selector ".content", text: /active_storage/
    end
  end
end
