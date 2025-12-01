# Fix Channels List

## Description

The channels list on server pages (e.g., `/servers/1`) doesn't show any channels even when channels have been joined.

## Investigation Required

The implementor must investigate why channels are not appearing. The controller code looks correct:

```ruby
@channels = @server.channels.joined.includes(:channel_users).order(:name)
```

Possible causes to investigate:

1. **Channels not being created in database** - Check if Channel records exist when joining
2. **`joined` flag not being set to true** - The `handle_join` event should set `joined: true`
3. **Query issue** - The `joined` scope may have issues
4. **View rendering issue** - The view may have conditional logic preventing display

## Debugging Steps

1. Connect to an IRC server and join a channel
2. Check rails console: `Channel.where(server_id: 1)` - are there records?
3. If records exist, check: `Channel.where(server_id: 1).pluck(:joined)` - are they `true`?
4. If records exist and joined is true, check the view rendering

## Behavior

### Expected
- After joining a channel, the server show page should list that channel
- The channel should show name, user count, View link, and Leave button
- Multiple channels should be listed alphabetically

### Current (Bug)
- Channels section shows "No channels yet" even after joining channels

## Tests

### Integration Tests

**Server page shows joined channels**
- Given: User has a server with 2 joined channels
- When: User visits the server page
- Then: Both channels are listed with correct info

**Server page hides parted channels**
- Given: User has a server with 1 joined channel and 1 parted channel
- When: User visits the server page
- Then: Only the joined channel is shown

**Channel count updates after join**
- Given: User is on the server page with 0 channels
- When: User joins a channel via the form
- Then: The channels list shows the new channel

## Implementation Notes

- The issue is likely in one of:
  1. `IrcEventHandler#handle_join` not setting `joined: true`
  2. The join event data structure mismatch (similar to names issue)
  3. Channel creation logic in `ChannelsController#create`

- Check `serialize_join_event` - it uses `channel:` but `handle_join` expects `data[:target]`

## Dependencies

None - this is a bug fix for existing functionality.
