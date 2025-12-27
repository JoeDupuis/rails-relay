require "application_system_test_case"

class NicknameLiveUpdateTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)
  end

  test "nickname updates in real-time on server page" do
    server = @user.servers.create!(
      address: "#{@test_id}-nick.example.chat",
      nickname: "oldnick",
      connected_at: Time.current
    )

    sign_in_as(@user)
    visit server_path(server)

    assert_selector ".nickname strong", text: "oldnick"

    server.update!(nickname: "newnick")
    perform_enqueued_jobs

    assert_selector ".nickname strong", text: "newnick", wait: 5
  end
end
