# Real-time Connection Status Updates

## Description

When a user clicks Connect or Disconnect on a server, the UI should update in real-time to reflect the new connection state without requiring a page refresh. Currently, the `connected` and `disconnected` events from IRC update `Server.connected_at` but don't broadcast UI changes.

## Behavior

### Connection Flow

1. User clicks "Connect" button on server page
2. Request goes to `ConnectionsController#create`, redirects back to server page
3. IRC connection is established asynchronously
4. `IrcEventHandler#handle_connected` is called, updates `Server.connected_at`
5. **NEW**: Server broadcasts Turbo Stream to update the status indicator and actions section
6. UI updates without page refresh:
   - Status indicator changes from "○ Disconnected" to "● Connected"
   - "Connect" button changes to "Disconnect" button
   - "Join Channel" section appears

### Disconnection Flow

1. User clicks "Disconnect" (or connection drops)
2. `IrcEventHandler#handle_disconnected` is called, sets `Server.connected_at` to nil
3. **NEW**: Server broadcasts Turbo Stream to update status and actions
4. UI updates:
   - Status indicator changes to "○ Disconnected"
   - "Disconnect" button changes to "Connect"
   - "Join Channel" section hides

## Models

### Server

Add `after_update_commit` callback to broadcast connection status changes:

```ruby
after_update_commit :broadcast_connection_status, if: :saved_change_to_connected_at?
```

The broadcast should replace:
- The status section (indicator + since timestamp)
- The actions section (Connect/Disconnect button)
- The join section (show/hide based on connected state)

## Implementation Notes

- Server show view already has `turbo_stream_from @server` subscription
- Use `broadcast_replace_to` with partials for each section that needs updating
- Consider using a single partial that includes all connection-dependent UI, or multiple targeted replacements
- The existing `broadcast_nickname_change` callback is a good reference pattern

## Tests

### Model Tests

**Server broadcasts connection status on connect**
- Given: A server with `connected_at: nil`
- When: Server is updated with `connected_at: Time.current`
- Then: Turbo Stream broadcast is sent to the server's stream

**Server broadcasts connection status on disconnect**
- Given: A server with `connected_at` set
- When: Server is updated with `connected_at: nil`
- Then: Turbo Stream broadcast is sent to the server's stream

### Integration Tests

**Server page updates on connect event**
- Given: User is viewing disconnected server page
- When: Connected event is received by IrcEventHandler
- Then: Page shows "● Connected" status without refresh
- And: Disconnect button is visible
- And: Join Channel section is visible

**Server page updates on disconnect event**
- Given: User is viewing connected server page
- When: Disconnected event is received by IrcEventHandler
- Then: Page shows "○ Disconnected" status without refresh
- And: Connect button is visible
- And: Join Channel section is hidden

## Dependencies

None - this builds on existing infrastructure.
