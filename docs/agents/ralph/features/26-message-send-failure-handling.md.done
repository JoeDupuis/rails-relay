# Message Send Failure Handling

## Description

When sending a message fails (e.g., IRC connection is gone, service unavailable), the current behavior:
1. Creates message locally (appears in UI as sent)
2. Tries to send IRC command
3. If 404 (connection not found), catches exception and sets flash
4. But message still appears as sent - misleading!

The fix: Don't create the message until we confirm IRC command was accepted. If it fails, show error and mark server as disconnected.

## Behavior

### Current Flow (Broken)

1. User types message, submits
2. `Message.create!` - message appears in UI immediately
3. `send_irc_command` - tries to send to IRC
4. If fails with 404, flash alert set but message already shown

### New Flow

1. User types message, submits
2. Try `send_irc_command` FIRST
3. If succeeds (202 Accepted):
   - Create message record
   - Message appears in UI
4. If fails with `ConnectionNotFound` (404):
   - Don't create message
   - Mark server as disconnected (`connected_at = nil`)
   - Reset channel states (like disconnect event)
   - Show error to user
   - Redirect to server page (connection lost)
5. If fails with `ServiceUnavailable`:
   - Don't create message
   - Show error: "IRC service unavailable"
   - Stay on channel page (might be temporary)

### Error Display

For Turbo Stream responses, need to handle errors differently:
- Can't just set flash and redirect (breaks Turbo)
- Use Turbo Stream to show error in channel view
- Or redirect with Turbo

### Disconnect on Failure

When message send fails with 404:
- Server is not connected in IRC service
- Call disconnect logic:
  ```ruby
  server.update!(connected_at: nil)
  server.channels.update_all(joined: false)
  ChannelUser.joins(:channel).where(channels: { server_id: server.id }).delete_all
  ```
- Broadcast disconnected status

## Implementation Notes

- Reorder operations in `MessagesController#send_message`, `send_irc_action`, `send_pm`
- Move `Message.create!` after successful `send_irc_command`
- Extract disconnect logic to `Server#mark_disconnected!` method (reusable)
- For turbo_stream format, render error stream or use `turbo_stream.redirect_to`

### Server#mark_disconnected!

```ruby
def mark_disconnected!
  transaction do
    update!(connected_at: nil)
    channels.update_all(joined: false)
    ChannelUser.joins(:channel).where(channels: { server_id: id }).delete_all
  end
end
```

## Tests

### Controller Tests

**Message not created on connection failure**
- Given: Server appears connected but IRC service returns 404
- When: POST message to channel
- Then: No message record created
- And: Server marked as disconnected

**Message created on success**
- Given: Connected server, IRC service accepts command
- When: POST message to channel
- Then: Message record created
- And: Response includes turbo stream to clear input

**Server disconnected on send failure**
- Given: Server with `connected_at` set
- When: Message send fails with ConnectionNotFound
- Then: `connected_at` is nil
- And: All channels `joined: false`

**Service unavailable doesn't disconnect**
- Given: Connected server
- When: Message send fails with ServiceUnavailable
- Then: Server still shows connected
- And: Error shown to user

### Model Tests

**Server#mark_disconnected! clears connection state**
- Given: Server with 2 joined channels
- When: `server.mark_disconnected!`
- Then: `connected_at` is nil
- And: Both channels `joined: false`
- And: Channel users cleared

### Integration Tests

**User sees error when message fails**
- Given: User in channel, server not actually connected
- When: User sends message
- Then: Error is displayed
- And: User redirected to server page
- And: Server shows disconnected

**Successful message appears in UI**
- Given: User in connected channel
- When: User sends message (IRC service accepts)
- Then: Message appears in message list
- And: Input field is cleared

## Dependencies

- Feature 21 (real-time connection status) for disconnect broadcasts
- Feature 23 (channel joined state reset) for `mark_disconnected!` logic
