require "test_helper"

class MessagesHelperTest < ActionView::TestCase
  include MessagesHelper

  test "linkify converts URLs to anchor tags" do
    result = linkify("Check out https://example.com for more")
    assert_equal 'Check out <a href="https://example.com" target="_blank" rel="noopener noreferrer">https://example.com</a> for more', result
  end

  test "linkify handles multiple URLs" do
    result = linkify("See https://a.com and https://b.com")
    assert_includes result, '<a href="https://a.com" target="_blank" rel="noopener noreferrer">https://a.com</a>'
    assert_includes result, '<a href="https://b.com" target="_blank" rel="noopener noreferrer">https://b.com</a>'
  end

  test "linkify escapes HTML in message content" do
    result = linkify("Hello <script>alert('xss')</script> https://example.com")
    assert_includes result, "&lt;script&gt;"
    assert_includes result, '<a href="https://example.com"'
    assert_not_includes result, "<script>"
  end

  test "linkify handles messages without URLs" do
    result = linkify("Hello world")
    assert_equal "Hello world", result
  end

  test "linkify handles empty content" do
    assert_equal "", linkify("")
  end

  test "linkify handles nil content" do
    assert_nil linkify(nil)
  end

  test "linkify handles http URLs" do
    result = linkify("Visit http://insecure.com now")
    assert_includes result, '<a href="http://insecure.com" target="_blank" rel="noopener noreferrer">http://insecure.com</a>'
  end

  test "format_message links URLs in regular messages" do
    message = Message.new(message_type: "privmsg", content: "Check https://example.com")
    result = format_message(message)
    assert_includes result, '<a href="https://example.com" target="_blank" rel="noopener noreferrer">https://example.com</a>'
  end

  test "format_message links URLs in quit reasons" do
    message = Message.new(message_type: "quit", sender: "bob", content: "See https://example.com for details")
    result = format_message(message)
    assert_includes result, "bob quit"
    assert_includes result, '<a href="https://example.com" target="_blank" rel="noopener noreferrer">https://example.com</a>'
  end

  test "format_message links URLs in part reasons" do
    message = Message.new(message_type: "part", sender: "alice", content: "Bye https://farewell.com later")
    result = format_message(message)
    assert_includes result, "alice left"
    assert_includes result, '<a href="https://farewell.com" target="_blank" rel="noopener noreferrer">https://farewell.com</a>'
  end

  test "format_message links URLs in topic changes" do
    message = Message.new(message_type: "topic", sender: "op", content: "New topic https://topic.com")
    result = format_message(message)
    assert_includes result, "op changed topic to:"
    assert_includes result, '<a href="https://topic.com" target="_blank" rel="noopener noreferrer">https://topic.com</a>'
  end

  test "format_message returns html_safe string" do
    message = Message.new(message_type: "privmsg", content: "Hello https://example.com")
    result = format_message(message)
    assert result.html_safe?
  end
end
