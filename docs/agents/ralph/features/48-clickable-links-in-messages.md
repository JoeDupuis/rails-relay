# Clickable Links in Chat Messages

## Description

When someone sends a URL in a chat message, it should be rendered as a clickable link. Currently, URLs are displayed as plain text.

## Current Behavior

Message content like "Check out https://example.com" is displayed as plain text. Users cannot click on URLs.

## Expected Behavior

URLs in message content should be automatically detected and rendered as clickable links that open in a new tab.

## Files to Modify

- `app/helpers/messages_helper.rb` - Add URL detection and linking to `format_message`

## Implementation

### URL Detection

Use a regex to detect URLs in message content. The Rails `auto_link` helper was removed in Rails 4, so we need to implement our own or use the `rinku` gem.

For simplicity, use a basic regex approach with `html_safe` after proper escaping:

```ruby
module MessagesHelper
  URL_REGEX = %r{(https?://[^\s<>\[\]]+)}i

  def format_message(message)
    content = case message.message_type
    when "join"
      "#{message.sender} joined"
    when "part"
      "#{message.sender} left" + (message.content.present? ? " (#{message.content})" : "")
    when "quit"
      "#{message.sender} quit" + (message.content.present? ? " (#{message.content})" : "")
    when "kick"
      "#{message.sender} #{message.content}"
    when "topic"
      "#{message.sender} changed topic to: #{message.content}"
    when "nick"
      "#{message.sender} is now known as #{message.content}"
    else
      message.content
    end

    linkify(content)
  end

  private

  def linkify(text)
    return text if text.blank?

    escaped = ERB::Util.html_escape(text)
    linked = escaped.gsub(URL_REGEX) do |url|
      %(<a href="#{url}" target="_blank" rel="noopener noreferrer">#{url}</a>)
    end
    linked.html_safe
  end
end
```

### Security Considerations

1. **HTML escape first** - Escape the message content before adding link tags to prevent XSS
2. **Use `noopener noreferrer`** - Prevent tabnapping attacks when opening links in new tabs
3. **Only match http/https** - Don't linkify `javascript:` or other dangerous schemes

### URL Regex Notes

The regex `%r{(https?://[^\s<>\[\]]+)}i` matches:
- `https://` or `http://`
- Followed by any non-whitespace, non-angle-bracket, non-bracket characters
- Case insensitive

This handles most common URLs while avoiding matches within HTML tags. It may capture trailing punctuation (like periods at end of sentences), but this is acceptable for IRC chat context.

## Tests

### Helper Tests

**linkify converts URLs to anchor tags**
- Input: "Check out https://example.com for more"
- Expected: "Check out <a href=\"https://example.com\" target=\"_blank\" rel=\"noopener noreferrer\">https://example.com</a> for more"

**linkify handles multiple URLs**
- Input: "See https://a.com and https://b.com"
- Expected: Both URLs linked

**linkify escapes HTML in message content**
- Input: "Hello <script>alert('xss')</script> https://example.com"
- Expected: Script tags escaped, URL linked

**linkify handles messages without URLs**
- Input: "Hello world"
- Expected: "Hello world" (unchanged, escaped)

**linkify handles empty/nil content**
- Input: nil or ""
- Expected: Returns input as-is

**format_message links URLs in regular messages**
- Message with type "privmsg" and content containing URL
- Expected: URL is linked

**format_message links URLs in quit/part reasons**
- Message type "quit" with content "See https://example.com"
- Expected: Output includes linked URL

### System Tests

**URLs in chat messages are clickable**
1. Sign in
2. Navigate to channel
3. Receive message containing "https://example.com"
4. Verify the URL is rendered as a link
5. Verify link has target="_blank"

**Uploaded file URLs are clickable**
1. Sign in
2. Navigate to channel
3. Receive message with uploaded file URL
4. Verify URL is clickable

## Dependencies

None

## Implementation Notes

- The regex approach is simple and sufficient for IRC chat. A more sophisticated approach (like using URI.parse) could be used but adds complexity.
- Trailing punctuation captured in URLs is acceptable for IRC context where formal sentences are rare.
- Consider adding CSS styling for links in messages (underline, color) in `message-item.css`.
