# Dismiss Flash Messages on Status Change

## Description

When clicking "Connect" or "Disconnect", a flash message ("Connecting...", "Disconnecting...") is shown. These messages persist until the next page load even after the connection status changes.

The flash should be dismissed when the server's connection status is updated via Turbo Stream.

## Behavior

When the server broadcasts a connection status change:
1. The status indicator updates (already working)
2. The actions section updates (already working)
3. The flash message area is cleared

## Implementation

### Option 1: Broadcast flash removal

Add a Turbo Stream broadcast to clear the flash when connection status changes:

```ruby
def broadcast_connection_status
  # Existing broadcasts...

  # Clear flash messages
  broadcast_remove_to(self, target: "flash_notice")
  broadcast_remove_to(self, target: "flash_alert")
end
```

Update layout to add IDs to flash elements:
```erb
<% if flash[:notice] %>
  <div class="notice" id="flash_notice"><%= flash[:notice] %></div>
<% end %>
<% if flash[:alert] %>
  <div class="alert" id="flash_alert"><%= flash[:alert] %></div>
<% end %>
```

### Option 2: Auto-dismiss with JavaScript

Add a Stimulus controller that auto-dismisses flash messages after a timeout, or when a specific Turbo event occurs.

**Recommendation**: Use Option 1 - it's simpler and more explicit. The flash goes away exactly when the status changes.

## Views

Update `app/views/layouts/application.html.erb`:

```erb
<main class="main">
  <div id="flash_notice">
    <% if flash[:notice] %>
      <div class="notice"><%= flash[:notice] %></div>
    <% end %>
  </div>
  <div id="flash_alert">
    <% if flash[:alert] %>
      <div class="alert"><%= flash[:alert] %></div>
    <% end %>
  </div>
  <%= yield %>
</main>
```

Note: The wrapper divs ensure the Turbo Stream remove action has a target even when there's no flash.

## Models

Update `Server#broadcast_connection_status`:

```ruby
def broadcast_connection_status
  broadcast_replace_to(self, target: dom_id(self, :status), partial: "servers/status", locals: { server: self })
  broadcast_replace_to(self, target: dom_id(self, :actions), partial: "servers/actions", locals: { server: self })
  broadcast_replace_to(self, target: dom_id(self, :join), partial: "servers/join", locals: { server: self })

  broadcast_replace_to(self, target: "flash_notice", html: "")
  broadcast_replace_to(self, target: "flash_alert", html: "")
end
```

## Tests

### Integration Tests

**Flash is cleared when connection completes**
- Given: User clicks "Connect" on server page
- And: Flash shows "Connecting..."
- When: IrcEventHandler processes connected event
- Then: Flash message is no longer visible

**Flash is cleared when disconnection completes**
- Given: User clicks "Disconnect" on server page (connected server)
- And: Flash shows "Disconnecting..."
- When: IrcEventHandler processes disconnected event
- Then: Flash message is no longer visible

### System Tests

**Connecting flash disappears after connection**
- Given: User on server page (disconnected)
- When: User clicks "Connect"
- Then: "Connecting..." flash appears
- When: Connection completes (simulate via test)
- Then: Flash is no longer visible
- And: Status shows "Connected"

## Implementation Notes

- Using `broadcast_replace_to` with empty `html:` instead of `broadcast_remove_to` because remove would delete the wrapper div, preventing future broadcasts from having a target
- Alternative: use `broadcast_update_to` with Turbo 8's morph mode

## Dependencies

None - independent fix.
