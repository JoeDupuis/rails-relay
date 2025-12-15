require "test_helper"
require "webmock/minitest"

class UploadsControllerTest < ActionDispatch::IntegrationTest
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

  def valid_png_file
    Rack::Test::UploadedFile.new(
      StringIO.new(png_data),
      "image/png",
      true,
      original_filename: "test.png"
    )
  end

  def png_data
    "\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xDE\x00\x00\x00\x0CIDAT\x08\xD7c\xF8\xFF\xFF?\x00\x05\xFE\x02\xFE\xA7V\xA3\x00\x00\x00\x00IEND\xAEB`\x82".b
  end

  def json_headers
    { "Accept" => "application/json" }
  end

  test "POST with valid PNG creates blob and message" do
    server = create_server
    channel = create_channel(server)

    file = fixture_file_upload("test.png", "image/png")

    assert_difference -> { ActiveStorage::Blob.count } do
      assert_difference -> { Message.count } do
        post channel_uploads_path(channel), params: { file: file }, headers: json_headers
      end
    end

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["url"].present?
    assert json["message_id"].present?

    message = Message.find(json["message_id"])
    assert_equal server, message.server
    assert_equal channel, message.channel
    assert_equal "testnick", message.sender
    assert_equal "privmsg", message.message_type
    assert_includes message.content, "/rails/active_storage/"
  end

  test "POST sends IRC command with URL" do
    server = create_server
    channel = create_channel(server)

    file = fixture_file_upload("test.png", "image/png")
    post channel_uploads_path(channel), params: { file: file }, headers: json_headers

    assert_requested(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands") do |req|
      body = JSON.parse(req.body)
      body["command"] == "privmsg" &&
        body["params"]["target"] == "#ruby" &&
        body["params"]["message"].include?("/rails/active_storage/")
    end
  end

  test "POST with invalid file type returns 422" do
    server = create_server
    channel = create_channel(server)

    file = fixture_file_upload("test.pdf", "application/pdf")

    assert_no_difference -> { ActiveStorage::Blob.count } do
      assert_no_difference -> { Message.count } do
        post channel_uploads_path(channel), params: { file: file }, headers: json_headers
      end
    end

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "Invalid file type or size", json["error"]
  end

  test "POST with file too large returns 422" do
    server = create_server
    channel = create_channel(server)

    large_file = Rack::Test::UploadedFile.new(
      StringIO.new("x" * (11 * 1024 * 1024)),
      "image/png",
      true,
      original_filename: "large.png"
    )

    assert_no_difference -> { ActiveStorage::Blob.count } do
      assert_no_difference -> { Message.count } do
        post channel_uploads_path(channel), params: { file: large_file }, headers: json_headers
      end
    end

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "Invalid file type or size", json["error"]
  end

  test "POST without file returns 422" do
    server = create_server
    channel = create_channel(server)

    post channel_uploads_path(channel), params: {}, headers: json_headers

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "Invalid file type or size", json["error"]
  end

  test "POST when server not connected returns 503" do
    server = create_server
    channel = create_channel(server)
    WebMock.reset!
    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_return(status: 404, body: "", headers: {})

    file = fixture_file_upload("test.png", "image/png")

    assert_difference -> { ActiveStorage::Blob.count } do
      assert_difference -> { Message.count } do
        post channel_uploads_path(channel), params: { file: file }, headers: json_headers
      end
    end

    assert_response :service_unavailable
    json = JSON.parse(response.body)
    assert_includes json["error"], "not connected"
  end

  test "POST when IRC service unavailable returns 503" do
    server = create_server
    channel = create_channel(server)
    WebMock.reset!
    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_raise(Errno::ECONNREFUSED)

    file = fixture_file_upload("test.png", "image/png")

    assert_difference -> { ActiveStorage::Blob.count } do
      assert_difference -> { Message.count } do
        post channel_uploads_path(channel), params: { file: file }, headers: json_headers
      end
    end

    assert_response :service_unavailable
    json = JSON.parse(response.body)
    assert_includes json["error"], "Service unreachable"
  end

  test "user can only upload to their own channels" do
    server = create_server
    channel = create_channel(server)

    sign_out
    other_user = users(:jane)
    sign_in_as(other_user)

    file = fixture_file_upload("test.png", "image/png")
    post channel_uploads_path(channel), params: { file: file }, headers: json_headers

    assert_response :not_found
  end

  test "POST with JPEG file works" do
    server = create_server
    channel = create_channel(server)

    file = fixture_file_upload("test.jpg", "image/jpeg")

    assert_difference -> { ActiveStorage::Blob.count } do
      post channel_uploads_path(channel), params: { file: file }, headers: json_headers
    end

    assert_response :ok
  end

  test "POST with GIF file works" do
    server = create_server
    channel = create_channel(server)

    file = fixture_file_upload("test.gif", "image/gif")

    assert_difference -> { ActiveStorage::Blob.count } do
      post channel_uploads_path(channel), params: { file: file }, headers: json_headers
    end

    assert_response :ok
  end

  test "POST with WebP file works" do
    server = create_server
    channel = create_channel(server)

    file = fixture_file_upload("test.webp", "image/webp")

    assert_difference -> { ActiveStorage::Blob.count } do
      post channel_uploads_path(channel), params: { file: file }, headers: json_headers
    end

    assert_response :ok
  end
end
