require "application_system_test_case"

class FileUploadTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)
    stub_irc_command
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
      assert_selector ".message-attachment.-image img[src*='active_storage']"
      assert_selector ".message-attachment .download", text: "test.png"
    end
  end

  test "video upload plays inline" do
    channel = create_connected_channel
    sign_in_as(@user)
    visit channel_path(channel)

    find("input[name='message[file]']", visible: false).attach_file(file_fixture("test.mp4"))

    within ".message-item", wait: 5 do
      assert_selector ".message-attachment.-video video[controls][src*='active_storage']"
    end
  end

  test "pdf upload previews inline" do
    channel = create_connected_channel
    sign_in_as(@user)
    visit channel_path(channel)

    find("input[name='message[file]']", visible: false).attach_file(file_fixture("test.pdf"))

    within ".message-item", wait: 5 do
      assert_selector ".message-attachment.-pdf object[type='application/pdf']"
    end
  end

  test "other file types are shown as a download" do
    channel = create_connected_channel
    sign_in_as(@user)
    visit channel_path(channel)

    find("input[name='message[file]']", visible: false).attach_file(file_fixture("test.zip"))

    within ".message-item", wait: 5 do
      assert_selector ".message-attachment.-download a.download[href*='disposition=attachment']", text: "test.zip"
      assert_no_selector "img, video, audio, object"
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
      assert_selector ".message-attachment"
    end

    fill_in "Message #uploads", with: "lol"
    click_button "Send"

    assert_selector ".message-item", count: 2, wait: 5

    within all(".message-item").last do
      assert_selector ".content", text: "lol"
      assert_no_selector ".message-attachment"
    end
  end

  test "pasting an image into the message box uploads it and keeps the typed text" do
    channel = create_connected_channel
    sign_in_as(@user)
    visit channel_path(channel)

    fill_in "Message #uploads", with: "look at this"
    dispatch_file_event("paste", "test.png", "image/png")

    within ".message-item", wait: 5 do
      assert_selector ".message-attachment.-image img[src*='active_storage']"
    end
    assert_field "Message #uploads", with: "look at this"
  end

  test "dropping a file anywhere on the channel uploads it" do
    channel = create_connected_channel
    sign_in_as(@user)
    visit channel_path(channel)

    dispatch_file_event("drop", "test.zip", "application/zip")

    within ".message-item", wait: 5 do
      assert_selector ".message-attachment.-download a.download", text: "test.zip"
    end
  end

  private

  def dispatch_file_event(type, fixture, content_type)
    assert_selector ".message-input"
    execute_script(<<~JS, type, Base64.strict_encode64(file_fixture(fixture).binread), fixture, content_type)
      const [type, base64, name, contentType] = arguments
      const bytes = Uint8Array.from(atob(base64), (c) => c.charCodeAt(0))
      const transfer = new DataTransfer()
      transfer.items.add(new File([bytes], name, { type: contentType }))
      if (type === "paste") {
        document.querySelector(".message-input .field").dispatchEvent(new ClipboardEvent("paste", { clipboardData: transfer, bubbles: true, cancelable: true }))
      } else {
        const target = document.querySelector(".messages")
        for (const eventType of ["dragenter", "dragover", "drop"]) {
          target.dispatchEvent(new DragEvent(eventType, { dataTransfer: transfer, bubbles: true, cancelable: true }))
        }
      }
    JS
  end
end
