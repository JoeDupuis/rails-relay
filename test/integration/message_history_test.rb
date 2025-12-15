require "test_helper"
require "webmock/minitest"

class MessageHistoryTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
    sign_in_as(@user)
    @test_id = SecureRandom.hex(4)

    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_return(status: 202, body: "", headers: {})
  end

  def unique_address(base = "irc.example")
    "#{base}-#{@test_id}.chat"
  end

  def create_server(address: nil)
    address ||= unique_address
    @user.servers.create!(address: address, nickname: "testnick", connected_at: Time.current)
  end

  def create_channel(server, name: "#ruby", joined: true)
    Channel.create!(server: server, name: name, joined: joined)
  end

  test "user views channel with history and sees all messages" do
    server = create_server
    channel = create_channel(server)
    10.times { |i| Message.create!(server: server, channel: channel, sender: "nick", message_type: "privmsg", content: "msg_history_#{i}", created_at: (10 - i).minutes.ago) }

    get channel_path(channel)
    assert_response :ok

    10.times do |i|
      assert_match "msg_history_#{i}", response.body
    end
  end

  test "messages are displayed in chronological order" do
    server = create_server
    channel = create_channel(server)
    old = Message.create!(server: server, channel: channel, sender: "nick", message_type: "privmsg", content: "old_msg_content", created_at: 2.hours.ago)
    new_msg = Message.create!(server: server, channel: channel, sender: "nick", message_type: "privmsg", content: "new_msg_content", created_at: 1.hour.ago)

    get channel_path(channel)
    assert_response :ok
    old_pos = response.body.index(old.content)
    new_pos = response.body.index(new_msg.content)
    assert old_pos < new_pos, "Old message should appear before new message"
  end

  test "message list shows channel header with topic" do
    server = create_server
    channel = create_channel(server)
    channel.update!(topic: "Welcome to Ruby channel!")

    get channel_path(channel)
    assert_response :ok
    assert_match "Welcome to Ruby channel!", response.body
  end

  test "kick message displays correctly" do
    server = create_server
    channel = create_channel(server)
    Message.create!(
      server: server,
      channel: channel,
      sender: "lol",
      content: "was kicked by admin (bad behavior)",
      message_type: "kick"
    )

    get channel_path(channel)
    assert_response :ok
    assert_match "lol was kicked by admin (bad behavior)", response.body
  end
end
