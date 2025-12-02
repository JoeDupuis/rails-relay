# Auto-Join Channels on Reconnect

## Description

Some channels should automatically be rejoined when connecting to a server. This is controlled by an `auto_join` boolean on the Channel model. When a server connects, all channels with `auto_join: true` should automatically send JOIN commands.

## Behavior

### Auto-Join Flow

1. User connects to server (via Connect button)
2. `IrcEventHandler#handle_connected` is called
3. **NEW**: After updating `connected_at`, find all channels with `auto_join: true`
4. **NEW**: For each auto-join channel, send JOIN command via `InternalApiClient`
5. Normal join flow proceeds (IRC sends back JOIN event, we handle it)

### Setting Auto-Join

- Add `auto_join` checkbox to channel settings (or inline toggle)
- Default: `false` for new channels
- When user manually joins a channel, they can toggle auto-join on

### UI for Auto-Join

On server page channel list:
- Show auto-join indicator (e.g., "⟳" icon or "auto" badge)
- Toggle to enable/disable auto-join

On channel view header:
- Show auto-join status
- Toggle to enable/disable

## Models

### Channel

Add migration for `auto_join` boolean column:

```ruby
add_column :channels, :auto_join, :boolean, default: false, null: false
```

## Implementation Notes

- `handle_connected` needs access to `InternalApiClient` to send join commands
- Consider rate limiting joins if there are many auto-join channels
- JOIN commands should be sent after connection is fully established
- If JOIN fails, don't crash - log error and continue with others

## Tests

### Model Tests

**Channel auto_join defaults to false**
- Given: New channel created
- Then: `auto_join` is `false`

**Channel auto_join can be set to true**
- Given: Channel with `auto_join: false`
- When: Updated to `auto_join: true`
- Then: `auto_join` is `true`

### Unit Tests (IrcEventHandler)

**handle_connected sends JOIN for auto_join channels**
- Given: Server with 2 channels, one has `auto_join: true`
- When: `IrcEventHandler.handle(server, { type: "connected" })`
- Then: JOIN command sent for auto_join channel only

**handle_connected handles no auto_join channels**
- Given: Server with 2 channels, both `auto_join: false`
- When: `IrcEventHandler.handle(server, { type: "connected" })`
- Then: No JOIN commands sent

**handle_connected handles multiple auto_join channels**
- Given: Server with 3 auto_join channels
- When: Connected event received
- Then: JOIN sent for all 3 channels

### Controller Tests

**Update channel auto_join**
- Given: Existing channel
- When: PATCH with `auto_join: true`
- Then: Channel `auto_join` is updated

### Integration Tests

**Connect triggers auto-join**
- Given: Server with #general (auto_join: true) and #random (auto_join: false)
- When: User connects to server
- Then: JOIN #general is sent
- And: JOIN #random is NOT sent

## Dependencies

- Feature 23 (channel joined state reset) - channels need proper joined state management
