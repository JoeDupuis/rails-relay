require "test_helper"

class Channel::ReadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
    sign_in_as(@user)
    @test_id = SecureRandom.hex(4)
    @server = @user.servers.create!(address: "irc-#{@test_id}.example.chat", nickname: "testnick", connected_at: Time.current)
    @channel = Channel.create!(server: @server, name: "#test-#{@test_id}", joined: true)
  end

  test "POST /channels/:channel_id/read marks the channel as read" do
    first = Message.create!(server: @server, channel: @channel, sender: "alice", content: "one", message_type: "privmsg")
    @channel.update!(last_read_message_id: first.id)
    latest = Message.create!(server: @server, channel: @channel, sender: "alice", content: "two", message_type: "privmsg")

    post channel_read_path(@channel)

    assert_response :no_content
    assert_equal latest.id, @channel.reload.last_read_message_id
    assert_equal 0, @channel.unread_count
  end

  test "POST /channels/:channel_id/read cannot mark another user's channel" do
    other_server = users(:jane).servers.create!(address: "other-#{@test_id}.example.chat", nickname: "jane")
    other_channel = Channel.create!(server: other_server, name: "#other-#{@test_id}")

    post channel_read_path(other_channel)

    assert_response :not_found
  end
end
