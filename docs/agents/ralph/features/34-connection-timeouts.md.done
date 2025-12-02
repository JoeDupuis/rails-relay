# Connection Timeouts

## Description

IRC operations (connect, disconnect, join, etc.) can hang indefinitely if something goes wrong. Add timeouts to prevent the UI from waiting forever.

## Behavior

### Connect Timeout

When clicking "Connect":
1. Start a connection attempt
2. If not connected within 30 seconds, consider it failed
3. Mark server as disconnected and show error

Looking at yaic's `client.rb`:
```ruby
DEFAULT_CONNECT_TIMEOUT = 30

def connect(timeout: DEFAULT_CONNECT_TIMEOUT)
  # ...
  wait_until(timeout: timeout) { connected? }
end
```

yaic already has a connect timeout that raises `Yaic::TimeoutError`.

**Current gap**: If yaic raises `TimeoutError`, `IrcConnection#connect` doesn't handle it specially - it's caught by the generic rescue in `run`, sends an "error" event, then cleanup sends "disconnected".

This should work, but verify it does.

### Operation Timeouts

yaic also has operation timeouts:
```ruby
DEFAULT_OPERATION_TIMEOUT = 10

def join(channel, key = nil, timeout: DEFAULT_OPERATION_TIMEOUT)
  # ...
  wait_until(timeout: timeout) { channel_joined?(channel) }
end
```

If join times out, yaic raises `TimeoutError`. This will crash the event loop and disconnect.

**Decision needed**: Should we:
1. Let operation timeouts crash and disconnect (current implicit behavior)
2. Catch timeouts and send an error event without disconnecting

Recommendation: Option 1 is fine for MVP. If an operation times out, something is wrong with the connection.

### UI Feedback

The "Connecting..." flash should show a loading state. If connection fails after timeout:
1. Server is marked disconnected (via error -> disconnected flow)
2. Flash is cleared (per feature 29)
3. Status shows "Disconnected"

The user sees the transition from "Connecting..." to "Disconnected".

## Tests

### Unit Tests (IrcConnection)

**connect timeout triggers error and disconnect events**
- Given: yaic client that raises TimeoutError on connect
- When: IrcConnection starts
- Then: "error" event is sent with timeout message
- And: "disconnected" event is sent

### Integration Tests

**Connection timeout marks server disconnected**
- Given: Server attempting to connect
- When: EventsController receives error event with "timed out"
- And: EventsController receives disconnected event
- Then: Server.connected_at is nil

## Implementation Notes

yaic already handles timeouts. The main work is ensuring:
1. TimeoutError flows through error handling correctly
2. UI updates appropriately

This feature may just be verification that existing timeout handling works, plus any small fixes needed.

## Dependencies

- 30-handle-connection-errors (error handling must work first)
