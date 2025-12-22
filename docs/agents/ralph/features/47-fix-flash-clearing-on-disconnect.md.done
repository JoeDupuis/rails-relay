# Fix Flash Message Clearing on Disconnect

## Description

Flash messages (like "Connecting..." and "Disconnecting...") disappear after connecting to a server but persist after disconnecting. The same Turbo Stream broadcast mechanism should work for both.

## Current Behavior

1. User clicks "Connect" → flash "Connecting..." → flash clears ✓
2. User clicks "Disconnect" → flash "Disconnecting..." → flash persists ✗

## Investigation Required

The `broadcast_connection_status` callback fires when `connected_at` changes. This should work for both connect (sets `connected_at`) and disconnect (clears `connected_at` via `mark_disconnected!`).

Before implementing a fix, investigate:

1. **Does the callback fire on disconnect?**
   - Add a test that asserts `broadcast_connection_status` is called when `mark_disconnected!` is called
   - Check if `after_update_commit` works correctly within the `transaction` block in `mark_disconnected!`

2. **Does the broadcast reach the client?**
   - Check browser dev tools Network tab for Turbo Stream responses
   - Verify the page is subscribed to the server stream before the broadcast fires

3. **Is it a timing issue?**
   - Disconnect might fire faster than connect (no network handshake)
   - The page redirect might not complete before the broadcast

## Likely Root Cause

If investigation shows the broadcast fires but isn't received, it's a timing issue: the disconnect event fires before the redirected page has subscribed to the Turbo Stream.

## Solution

Once the cause is confirmed, **use AskUserQuestion** to report findings and ask how to proceed. Present the options:

### Option A: Broadcast to sidebar stream

The sidebar stream (`sidebar_#{user_id}`) is always subscribed via the layout. Broadcast flash clearing there instead of the server stream:

```ruby
def broadcast_connection_status
  # ... existing server-specific broadcasts ...

  # Clear flash via user-wide stream (always subscribed)
  broadcast_replace_to("sidebar_#{user_id}", target: "flash_notice", html: "")
  broadcast_replace_to("sidebar_#{user_id}", target: "flash_alert", html: "")
end
```

### Option B: Subscribe to user stream in layout

Add a user-wide Turbo Stream subscription in the layout that's always present, separate from server-specific subscriptions.

### Other

User may have a different solution in mind.

## Files to Investigate/Modify

- `app/models/server.rb` - `mark_disconnected!` and callback
- `app/models/irc_event_handler.rb` - `handle_disconnected`
- `app/views/layouts/application.html.erb` - flash markup and subscriptions

## Tests

### Investigation Tests

**broadcast_connection_status fires on mark_disconnected!**
- Given: Connected server
- When: `mark_disconnected!` is called
- Then: Assert broadcast was sent to clear flash

### Fix Tests (after cause is identified)

**flash clears on disconnect**
- System test that verifies flash disappears after disconnect

## Dependencies

None

## Implementation Notes

1. Reproduce the issue and investigate the actual cause
2. Once root cause is identified, use `AskUserQuestion` to explain the problem and ask which fix to implement
3. Do NOT implement a fix without user approval
