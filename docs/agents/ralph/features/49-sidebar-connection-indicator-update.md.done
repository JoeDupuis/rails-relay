# Sidebar Connection Indicator Live Update

## Description

When connecting to or disconnecting from a server, the green/gray connection indicator dot in the sidebar doesn't update in real-time. Users must force refresh the page to see the updated status.

## Current Behavior

1. Sidebar shows server with gray dot (disconnected)
2. User connects to server
3. Server page shows connected status
4. Sidebar still shows gray dot until page refresh

## Expected Behavior

The sidebar connection indicator should update in real-time when connection status changes, without requiring a page refresh.

## Root Cause

The `Server#broadcast_connection_status` callback only broadcasts to the server stream (for the server show page). The sidebar subscribes to a different stream (`sidebar_#{Current.user.id}`), so it doesn't receive connection status updates.

## Files to Modify

- `app/models/server.rb` - Add sidebar broadcast when connection status changes
- `app/views/shared/_sidebar.html.erb` - Add Turbo Stream target ID to connection indicator
- `app/views/shared/_server_sidebar_item.html.erb` - Create new partial for server group in sidebar

## Implementation

### Server Model

Add a broadcast to the sidebar stream when connection status changes:

```ruby
def broadcast_connection_status
  # Existing broadcasts to server stream...

  # Add sidebar broadcast
  broadcast_replace_to(
    "sidebar_#{user_id}",
    target: "server_#{id}_indicator",
    partial: "shared/connection_indicator",
    locals: { server: self }
  )
end
```

### Sidebar View Changes

Add a target ID to the connection indicator span:

```erb
<span id="server_<%= server.id %>_indicator"
      class="connection-indicator <%= server.connected? ? '-connected' : '-disconnected' %>">
</span>
```

Or extract to a partial:

```erb
<%# app/views/shared/_connection_indicator.html.erb %>
<span id="server_<%= server.id %>_indicator"
      class="connection-indicator <%= server.connected? ? '-connected' : '-disconnected' %>">
</span>
```

### Alternative: Replace Entire Server Group

If simpler, replace the entire server group div in the sidebar:

```ruby
broadcast_replace_to(
  "sidebar_#{user_id}",
  target: "servergroup_#{id}",
  partial: "shared/server_sidebar_group",
  locals: { server: self }
)
```

This would require extracting the server group into its own partial and adding a target ID.

## Tests

### Model Tests

**broadcast_connection_status broadcasts to sidebar stream**
- Given: Server with user
- When: `broadcast_connection_status` is called
- Then: Assert broadcast sent to "sidebar_#{user_id}" stream

**connection indicator update on connect**
- Given: Disconnected server
- When: Server connects (connected_at set)
- Then: Sidebar broadcast includes connected indicator class

**connection indicator update on disconnect**
- Given: Connected server
- When: Server disconnects (connected_at cleared)
- Then: Sidebar broadcast includes disconnected indicator class

### Integration Tests

**IrcEventHandler connected event updates sidebar**
- Given: Signed in user on any page with sidebar
- When: `handle_connected` is called for their server
- Then: Sidebar receives turbo stream to update indicator

**IrcEventHandler disconnected event updates sidebar**
- Given: Signed in user with connected server on any page
- When: `handle_disconnected` is called
- Then: Sidebar receives turbo stream to update indicator

### System Tests

**Sidebar indicator updates on connect**
1. Sign in
2. Navigate to any page (e.g., servers index)
3. Verify sidebar shows gray dot for server
4. Connect to server (via another tab or API call)
5. Verify sidebar dot turns green without page refresh

**Sidebar indicator updates on disconnect**
1. Sign in with connected server
2. Navigate to any page
3. Verify sidebar shows green dot
4. Disconnect server
5. Verify sidebar dot turns gray without page refresh

## Dependencies

None

## Implementation Notes

- The sidebar already subscribes to `sidebar_#{Current.user.id}` stream (first line of _sidebar.html.erb)
- Turbo Stream broadcasts need a unique target ID - using `server_#{id}_indicator` pattern
- Keep the partial simple - just the span element with the indicator class
- The broadcast uses `user_id` from the server association (not `Current.user.id`) to ensure it works in background job context
