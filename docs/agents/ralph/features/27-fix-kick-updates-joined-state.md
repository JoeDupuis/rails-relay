# Fix Kick Updates Joined State

## Description

When the current user gets kicked from a channel, the channel's `joined` status is not updated to `false`. This leaves the user seeing the channel as if they're still in it, and their messages fail silently.

## Behavior

When an IRC KICK event is received and the kicked user is the current server's nickname:
1. Update `channel.joined` to `false`
2. Clear all channel_users for that channel (same as when we part)

This mirrors the behavior already implemented for `handle_part` when `source_nick == @server.nickname`.

## Models

No model changes needed. The `Channel` model already has a `joined` boolean field.

## Implementation

Update `IrcEventHandler#handle_kick` to check if the kicked user is ourselves:

```ruby
def handle_kick
  channel = Channel.find_by(server: @server, name: data[:target])
  return unless channel

  kicked_nick = data[:kicked]

  if kicked_nick.casecmp?(@server.nickname)
    channel.update!(joined: false)
    channel.channel_users.destroy_all
  else
    channel.channel_users.find_by(nickname: kicked_nick)&.destroy
  end

  Message.create!(...)
end
```

Use `casecmp?` for case-insensitive comparison (IRC nicknames are case-insensitive).

## Tests

### Unit Tests (IrcEventHandler)

**handle_kick marks channel as not joined when we are kicked**
- Given: Server with nickname "testuser", channel "ruby" with `joined: true`
- When: handle_kick event with `kicked: "testuser"`
- Then: channel.joined is false
- And: channel.channel_users is empty

**handle_kick marks channel as not joined (case insensitive)**
- Given: Server with nickname "TestUser", channel "ruby" with `joined: true`
- When: handle_kick event with `kicked: "TESTUSER"`
- Then: channel.joined is false

**handle_kick only removes channel_user when someone else is kicked**
- Given: Server with nickname "testuser", channel "ruby" with channel_users ["other", "testuser"]
- When: handle_kick event with `kicked: "other"`
- Then: channel.joined is still true
- And: channel_users only contains "testuser"

### Integration Tests

**Getting kicked updates channel view**
- Given: User on channel show page for #ruby (joined)
- When: Server sends KICK event kicking the user
- Then: Page shows "You are not in this channel" banner
- And: Leave button becomes Join button

## Dependencies

None - this is a bug fix to existing functionality.
