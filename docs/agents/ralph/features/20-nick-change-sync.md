# Nick Change Sync

## Description

When the user's nickname changes (either via `/nick` command or forced by the server), the app should update `Server.nickname` to reflect the new nickname.

Currently, `IrcEventHandler#handle_nick` only updates `ChannelUser` records but doesn't update `Server.nickname` when it's the user's own nick that changed.

## Behavior

### Scenarios

1. **User changes own nick via /nick command**
   - User sends `/nick newnick` in a channel
   - Server accepts the change
   - `Server.nickname` should update to "newnick"
   - UI should reflect the new nickname

2. **Server forces nick change**
   - User connects with nick "joe"
   - Server changes it to "joe_" (because "joe" is in use)
   - `Server.nickname` should update to "joe_"
   - UI should reflect the new nickname

### UI Updates

When the user's nick changes:
- Server page header should show new nickname ("as **newnick**")
- Sidebar should update if it shows nickname anywhere
- Use Turbo Stream broadcast to update in real-time

## Implementation

### IrcEventHandler#handle_nick

Current code updates ChannelUsers but not Server.nickname:

```ruby
def handle_nick
  old_nick = source_nick
  new_nick = data[:new_nick]

  @server.channels.each do |channel|
    user = channel.channel_users.find_by(nickname: old_nick)
    user&.update!(nickname: new_nick)
  end
  # ... creates message
end
```

Add logic to check if `old_nick` matches `@server.nickname` (case-insensitive) and update:

```ruby
def handle_nick
  old_nick = source_nick
  new_nick = data[:new_nick]

  # Update server nickname if it's our nick that changed
  if old_nick.casecmp?(@server.nickname)
    @server.update!(nickname: new_nick)
  end

  # ... rest of existing code
end
```

### Real-time UI Update

Broadcast a Turbo Stream when `Server.nickname` changes to update the UI. Options:
1. Add callback to Server model
2. Broadcast from IrcEventHandler after updating

## Tests

### Unit Tests - IrcEventHandler

**handle_nick updates server nickname when own nick changes**
- Given: Server with nickname "joe"
- When: Nick event received with old_nick "joe", new_nick "joe_"
- Then: Server.nickname is updated to "joe_"

**handle_nick updates server nickname case-insensitively**
- Given: Server with nickname "Joe"
- When: Nick event received with old_nick "joe", new_nick "joe_"
- Then: Server.nickname is updated to "joe_"

**handle_nick does not update server nickname for other users**
- Given: Server with nickname "joe"
- When: Nick event received with old_nick "bob", new_nick "bobby"
- Then: Server.nickname remains "joe"

**handle_nick still updates channel_users for own nick**
- Given: Server with nickname "joe" and channel with ChannelUser "joe"
- When: Nick event received for own nick change to "joe_"
- Then: Both Server.nickname and ChannelUser.nickname are updated

### Integration Tests

**Nick change via /nick command updates server**
- Given: Connected server with nickname "joe"
- When: User sends "/nick newnick" and server confirms
- Then: Server page shows "as **newnick**"

## Implementation Notes

1. The nick event data structure from `serialize_nick_event`:
   ```ruby
   { old_nick: event.old_nick, new_nick: event.new_nick }
   ```
   But `handle_nick` uses `source_nick` (from `data[:source]`) for old_nick - verify this is correct

2. May need to fix data key mismatch if `serialize_nick_event` structure doesn't match what `handle_nick` expects

3. Consider broadcasting Server updates via Turbo Stream for real-time UI updates

## Dependencies

None - extends existing nick handling functionality.
