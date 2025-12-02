# Fix Kick Message Format

## Description

When someone is kicked, the message displays incorrectly. Example:
```
adminadmin was kicked (lol was kicked: kicked by admin)
```

Expected:
```
lol was kicked by admin (kicked)
```

Where "admin" is the kicker, "lol" is the kicked user, and "kicked" is the reason.

## Investigation

Current code in `IrcEventHandler#handle_kick`:
```ruby
kicked_nick = data[:kicked]
Message.create!(
  # ...
  content: "#{kicked_nick} was kicked: #{data[:text]}"
)
```

Current serializer in `IrcConnection#serialize_kick_event`:
```ruby
{
  source: event.by&.raw,     # kicker (full hostmask)
  target: event.channel,     # channel name
  kicked: event.user,        # kicked nick
  text: event.reason         # kick reason
}
```

In yaic `build_event_attributes`:
```ruby
when :kick
  {channel: message.params[0], user: message.params[1], by: message.source, reason: message.params[2]}
```

So:
- `event.user` = the kicked nick (correct)
- `event.by` = the kicker (Source object)
- `event.reason` = the kick reason (just the reason text)

The bug is:
1. `data[:text]` contains the raw reason from yaic
2. The message format has redundant "was kicked" text

**Wait** - the example shows `adminadmin`. This suggests `source_nick` (the kicker) is being concatenated with `kicked_nick`. Let me check:

In `handle_kick`:
```ruby
sender: source_nick,  # This is the kicker
content: "#{kicked_nick} was kicked: #{data[:text]}"
```

So the Message has:
- sender: "admin" (the kicker)
- content: "lol was kicked: kicked" (if reason was "kicked")

How does the message display? Let me check the message partial...

**The issue might be in the message display**, not the data. The `_message.html.erb` partial likely shows `sender + content` for kick messages.

## Behavior

Kick messages should display as:
```
<kicked_nick> was kicked by <kicker_nick> (<reason>)
```

If no reason:
```
<kicked_nick> was kicked by <kicker_nick>
```

## Implementation

Option 1: Store better content
```ruby
def handle_kick
  # ...
  reason_text = data[:text].present? ? " (#{data[:text]})" : ""
  Message.create!(
    # ...
    sender: kicked_nick,  # The kicked user is the "subject" of this message
    content: "kicked by #{source_nick}#{reason_text}",
    message_type: "kick"
  )
end
```

Display would show: "lol: kicked by admin (reason)"

Option 2: Store structured data, format in view
```ruby
Message.create!(
  sender: source_nick,  # kicker
  content: JSON.dump({ kicked: kicked_nick, reason: data[:text] }),
  message_type: "kick"
)
```

Then in the view, parse and format kick messages specially.

**Recommendation**: Option 1 is simpler. The message partial already handles different message types.

## Views

Update `messages/_message.html.erb` to handle kick messages:
```erb
<% if message.message_type == "kick" %>
  <span class="event"><%= message.sender %> <%= message.content %></span>
<% elsif message.message_type == "join" %>
  ...
```

Or if using the existing format helper in `MessagesHelper`.

## Tests

### Unit Tests (IrcEventHandler)

**handle_kick creates message with correct format**
- Given: Kick event with kicker "admin", kicked "lol", reason "bad behavior"
- When: handle_kick
- Then: Message created with sender: "lol", content: "kicked by admin (bad behavior)"

**handle_kick handles empty reason**
- Given: Kick event with kicker "admin", kicked "lol", reason nil
- When: handle_kick
- Then: Message created with content: "kicked by admin"

### Integration Tests

**Kick message displays correctly**
- Given: Channel with kick message
- When: Viewing channel
- Then: Message shows "lol kicked by admin (reason)"

## Implementation Notes

First investigate what the actual bug is by:
1. Looking at the message partial for kick messages
2. Checking what's stored in the database for a kick message

The `adminadmin` in the example is suspicious - it suggests string concatenation somewhere.

## Dependencies

None - bug fix.
