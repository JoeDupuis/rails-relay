# Connection Health Check Background Job

## Description

When the Rails server restarts, it loses track of IRC connections but the database still shows servers as connected (`connected_at` is set). This causes a misleading UI where servers appear connected but aren't.

A background job should periodically check if connections are actually alive and update the database accordingly.

## Behavior

### Health Check Job

A recurring background job (`ConnectionHealthCheckJob`) runs periodically:

1. Find all servers where `connected_at` is not null (appear connected)
2. For each server, check if the IRC connection actually exists
3. If connection doesn't exist, mark server as disconnected:
   - Set `connected_at` to nil
   - Set all channels `joined: false`
   - Clear channel_users
   - Broadcast status update to UI

### Checking Connection Status

Two approaches:

**Option A: Check IrcConnectionManager directly (same process)**
- Call `IrcConnectionManager.instance.connected?(server_id)`
- Fast, but only works if IRC service runs in same process

**Option B: Call status endpoint (separate process)**
- Call `InternalApiClient.status` to get list of active connections
- Compare against servers that show connected in DB
- Works across processes

Since the architecture uses a separate IRC service process, use Option B.

### Startup Check

On Rails boot, also run a check for stale connections:
- Add initializer that enqueues `ConnectionHealthCheckJob.perform_later`
- This handles the case where Rails restarts but IRC service died

### Job Configuration

- Run every 30 seconds (configurable)
- Use Solid Queue recurring schedule
- Don't run in test environment

## Implementation Notes

- Add `ConnectionHealthCheckJob` in `app/jobs/`
- Add recurring schedule to `config/recurring.yml` (Solid Queue)
- Add initializer `config/initializers/connection_health_check.rb`
- `InternalApiClient.status` endpoint should return list of connected server IDs
- Handle `ServiceUnavailable` - if IRC service is down, mark ALL servers as disconnected

### Status Endpoint Enhancement

The `/internal/irc/status` endpoint needs to return connected server IDs:

```json
{
  "connections": [1, 5, 12]
}
```

Currently it may just return a health check response. Update if needed.

## Tests

### Job Tests

**Job marks stale connections as disconnected**
- Given: Server with `connected_at` set but not in IRC service connections list
- When: `ConnectionHealthCheckJob.perform_now`
- Then: Server `connected_at` is nil
- And: All channels `joined: false`

**Job keeps valid connections connected**
- Given: Server with `connected_at` set AND in IRC service connections list
- When: `ConnectionHealthCheckJob.perform_now`
- Then: Server `connected_at` unchanged

**Job handles IRC service unavailable**
- Given: 2 servers showing connected
- And: IRC service is unreachable
- When: `ConnectionHealthCheckJob.perform_now`
- Then: Both servers marked as disconnected

**Job does nothing when no servers connected**
- Given: All servers have `connected_at: nil`
- When: `ConnectionHealthCheckJob.perform_now`
- Then: No changes made

### Controller Tests (StatusController)

**Status returns connected server IDs**
- Given: IRC connections for servers 1 and 3
- When: GET `/internal/irc/status`
- Then: Response includes `connections: [1, 3]`

### Integration Tests

**Stale connection detected on health check**
- Given: Server shows connected in DB
- But: IRC service has no connection for it
- When: Health check job runs
- Then: Server shows disconnected
- And: Channels reset to not joined

## Dependencies

- Feature 21 (real-time connection status) for broadcast infrastructure
- Feature 23 (channel joined state reset) for proper cleanup on disconnect
