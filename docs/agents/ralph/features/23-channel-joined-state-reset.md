# Channel Joined State Reset on Disconnect

## Description

When a server disconnects, all channels should have their `joined` status set to `false`. Currently, if you disconnect and reconnect, channels still show `joined: true` even though you're not actually in them on IRC.

This causes confusion because:
- Channel shows in sidebar as if you're in it
- Channel view lets you type messages
- Messages fail silently (404 from IRC service, or sent to channel you're not in)

## Behavior

### On Disconnect

When `IrcEventHandler#handle_disconnected` is called:
1. Update `Server.connected_at` to nil (existing)
2. **NEW**: Set `joined: false` on ALL channels for this server
3. **NEW**: Clear all `channel_users` for this server's channels
4. Broadcast connection status change (feature 21)

### Channel View When Not Joined

The channel view should clearly indicate when you're viewing a channel you're not currently in:
- Message input should be disabled/grayed out
- Show a banner: "You are not in this channel"
- Show "Join" button instead of "Leave" button in header

### Server Page Channel List

On the server page, channels that have `joined: false` should show differently:
- "Join" link instead of "View" link (or both)
- "Remove" link instead of "Leave" link
- Visual indicator that you're not in the channel (grayed out, italic, etc.)

## Implementation Notes

- `handle_disconnected` should call `@server.channels.update_all(joined: false)`
- `handle_disconnected` should call `ChannelUser.joins(:channel).where(channels: { server_id: @server.id }).delete_all`
- Channel view needs conditional rendering based on `@channel.joined`
- Server view channel list needs conditional rendering

## Tests

### Unit Tests (IrcEventHandler)

**handle_disconnected resets all channel joined status**
- Given: Server with 3 channels, all `joined: true`
- When: `IrcEventHandler.handle(server, { type: "disconnected" })`
- Then: All 3 channels have `joined: false`

**handle_disconnected clears all channel users**
- Given: Server with 2 channels, each with 5 users
- When: `IrcEventHandler.handle(server, { type: "disconnected" })`
- Then: All channel_users for both channels are deleted

### Controller Tests

**Channel show when not joined shows disabled input**
- Given: Channel with `joined: false`
- When: GET channel page
- Then: Response includes disabled message input
- And: Response includes "not in this channel" message
- And: Response includes "Join" button (not "Leave")

### Integration Tests

**Disconnect resets channel state**
- Given: User connected to server with 2 joined channels
- When: Disconnected event is received
- Then: Both channels show `joined: false`
- And: Channel users are cleared

**Channel view after disconnect shows not-joined state**
- Given: User was in #test channel
- And: Server disconnected
- When: User views #test channel
- Then: Message input is disabled
- And: "Join" button is shown

### System Tests

**Channel input disabled when not joined**
- Given: User viewing channel they're not joined to
- Then: Message input field is disabled
- And: Cannot submit messages

## Dependencies

- Feature 21 (real-time connection status) for broadcast infrastructure
