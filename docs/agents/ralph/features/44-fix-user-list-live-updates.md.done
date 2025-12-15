# Fix User List Live Updates

## Description

The user list on the right side of channel views does not update in real-time. Symptoms:

1. When joining a channel, the user list shows 0 users initially. Refreshing shows all users.
2. When another user joins/parts the channel, the list doesn't update automatically.

This feature worked before and has regressed. The task is to investigate what broke and fix it.

## Current Architecture

**Turbo Stream Subscription** (`channels/show.html.erb`):
```erb
<%= turbo_stream_from @channel %>
<%= turbo_stream_from @channel, :users %>
```

**ChannelUser Broadcasts** (`app/models/channel_user.rb`):
```ruby
after_create_commit :broadcast_user_list_on_create
after_destroy_commit :broadcast_user_list_on_destroy
after_update_commit :broadcast_user_list_on_update, if: :saved_change_to_modes?

def broadcast_user_list
  channel.reload
  broadcast_replace_to(
    [ channel, :users ],
    target: "channel_#{channel.id}_user_list",
    partial: "channels/user_list",
    locals: { channel: channel }
  )
end
```

**User List Partial** (`channels/_user_list.html.erb`):
```erb
<div id="channel_<%= channel.id %>_user_list" class="user-list">
  ...
</div>
```

**Expected Flow**:
1. IRC event (join/part/names) triggers IrcEventHandler
2. ChannelUser record created/destroyed
3. Callback broadcasts Turbo Stream
4. Browser receives stream and replaces user list div

## Investigation Steps

### Step 1: Verify Broadcasts Are Being Sent

Add temporary logging or use Rails console to check if broadcasts fire:

```ruby
# In ChannelUser model, temporarily add:
def broadcast_user_list
  Rails.logger.info "Broadcasting user list for channel #{channel.id}"
  # ... existing code
end
```

Join a channel and check logs.

### Step 2: Verify ActionCable Connection

Check browser DevTools Network tab for WebSocket connection:
- Should see `cable` connection
- Should see subscription confirmations

### Step 3: Verify Stream Names Match

The subscription is `turbo_stream_from @channel, :users` which creates stream name like `channels:123:users`.
The broadcast uses `broadcast_replace_to([channel, :users], ...)`.

These should match. Verify by checking ActionCable logs.

### Step 4: Check for Timing Issues

When you join a channel, the page loads immediately but NAMES event comes later.
The user SHOULD receive the broadcast if subscribed. Check if there's a race condition where the page hasn't subscribed yet when the broadcast fires.

### Step 5: Check Turbo Stream Processing

Verify browser receives the Turbo Stream. In DevTools console:
```javascript
Turbo.StreamObserver.prototype.receivedMessageResponse = function(response) {
  console.log('Turbo Stream received:', response);
  // call original
}
```

## Likely Causes

1. **Target container replaced by broadcast**: If `broadcast_replace_to` replaces the element that HAS the target ID (instead of replacing content INSIDE it), subsequent broadcasts won't find the target. The partial being broadcast must preserve the target ID on the outer element.
2. **ActionCable not connected**: Check if WebSocket connection is established
3. **Wrong stream name**: Mismatch between subscription and broadcast stream names
4. **Target ID mismatch**: broadcast targets `channel_X_user_list` but DOM has different ID
5. **Broadcast not firing**: Callback not triggered or error in broadcast
6. **Turbo not processing**: JavaScript error preventing Turbo from processing stream

### Target Container Issue (Most Likely)

If the broadcast replaces the container that has `id="channel_X_user_list"`, and the replacement HTML doesn't include that same ID on its outer element, subsequent broadcasts fail silently.

Check `channels/_user_list.html.erb`:
```erb
<div id="channel_<%= channel.id %>_user_list" class="user-list">
  ...
</div>
```

The broadcast partial MUST have this same ID on its outermost element. If something changed the partial structure (e.g., wrapping in another div, or the ID moved to an inner element), broadcasts after the first one will fail.

## Behavior

When fixed, the user list should:

1. Show all users immediately when joining a channel (after NAMES event processed)
2. Update automatically when another user joins
3. Update automatically when another user parts/quits
4. Update when a user's modes change (op/voice)

## Tests

### System Tests

**User list updates on join**
- Given: User viewing channel with existing users
- When: Another user joins the channel (simulate via IrcEventHandler)
- Then: New user appears in user list without page refresh

**User list updates on part**
- Given: User viewing channel with multiple users
- When: One user parts the channel
- Then: User disappears from list without page refresh

**User list updates on quit**
- Given: User viewing channel where user is in multiple channels
- When: User quits server
- Then: User disappears from all channel user lists

**User list shows all users after joining**
- Given: Channel with 5 users already in it
- When: User joins channel and page loads
- And: NAMES event is processed
- Then: User list shows all 5 users (plus self = 6)

**User list updates on mode change**
- Given: User viewing channel
- When: A user is given operator status
- Then: User moves to Operators section without page refresh

### Integration Tests

**ChannelUser broadcast fires on create**
- Given: Channel exists
- When: ChannelUser created
- Then: Turbo Stream broadcast is sent to `[channel, :users]`

**ChannelUser broadcast fires on destroy**
- Given: ChannelUser exists
- When: ChannelUser destroyed
- Then: Turbo Stream broadcast is sent

**NAMES event triggers user list update**
- Given: User subscribed to channel stream
- When: NAMES event processed via IrcEventHandler
- Then: User list is updated with all names

## Implementation Notes

- Use `assert_turbo_stream_broadcasts` in model tests to verify broadcasts
- System tests need WebSocket connections - ensure test server supports ActionCable
- May need to add small waits in system tests for async updates
- If timing is the issue, consider:
  - Loading user list via Turbo Frame that auto-refreshes
  - Initial page load fetches users from DB (should be there after NAMES)
  - The real issue is likely elsewhere since page refresh works

## Dependencies

None - this is a bug fix for existing functionality.
