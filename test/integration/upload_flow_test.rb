require "test_helper"
require "webmock/minitest"

class UploadFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    @test_id = SecureRandom.hex(4)

    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_return(status: 202, body: "", headers: {})
  end

  def unique_address(base = "irc.example")
    "#{base}-#{@test_id}.chat"
  end

  def create_connected_server
    @user.servers.create!(address: unique_address, nickname: "testnick", connected_at: Time.current)
  end

  def json_headers
    { "Accept" => "application/json" }
  end

  test "user uploads image and URL appears as message" do
    server = create_connected_server
    channel = Channel.create!(server: server, name: "#ruby", joined: true)

    file = fixture_file_upload("test.png", "image/png")

    post channel_uploads_path(channel), params: { file: file }, headers: json_headers

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["url"].present?

    message = Message.last
    assert_equal channel, message.channel
    assert_equal server, message.server
    assert_equal "testnick", message.sender
    assert_equal "privmsg", message.message_type
    assert_includes message.content, "/rails/active_storage/"

    assert_requested(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands") do |req|
      body = JSON.parse(req.body)
      body["command"] == "privmsg" &&
        body["params"]["target"] == "#ruby" &&
        body["params"]["message"].include?("/rails/active_storage/")
    end
  end

  test "uploaded blob URL is accessible" do
    server = create_connected_server
    channel = Channel.create!(server: server, name: "#ruby", joined: true)

    file = fixture_file_upload("test.png", "image/png")

    post channel_uploads_path(channel), params: { file: file }, headers: json_headers

    assert_response :ok
    json = JSON.parse(response.body)
    url = json["url"]

    uri = URI.parse(url)
    get uri.path

    assert_response :redirect
  end

  test "upload URLs are unique and not guessable" do
    server = create_connected_server
    channel = Channel.create!(server: server, name: "#ruby", joined: true)

    file1 = fixture_file_upload("test.png", "image/png")
    post channel_uploads_path(channel), params: { file: file1 }, headers: json_headers
    url1 = JSON.parse(response.body)["url"]

    file2 = fixture_file_upload("test.png", "image/png")
    post channel_uploads_path(channel), params: { file: file2 }, headers: json_headers
    url2 = JSON.parse(response.body)["url"]

    assert_not_equal url1, url2

    path1 = URI.parse(url1).path
    path2 = URI.parse(url2).path
    assert_not_equal path1, path2
  end
end
