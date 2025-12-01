# Fix User List

## Description

The user list on channel pages always shows "0 users" even when users are in the channel. This affects both initial load and real-time updates when users join/leave.

## Investigation Required

The implementor must investigate and fix both issues:

### Issue 1: Initial User List Not Loading

When viewing a channel page (e.g., `/channels/3`), the user list shows "0 users" instead of the actual users in the channel.

Possible causes to investigate:
- The `names` event from yaic may not be firing or may have different data structure
- `IrcConnection#serialize_names_event` uses `users:` but `IrcEventHandler#handle_names` expects `data[:names]` - this is likely a bug
- The channel_users may not be created in the database

### Issue 2: Real-time Updates Not Working

When users join or leave a channel, the user list doesn't update in real-time.

Possible causes to investigate:
- No Turbo Stream broadcasts for channel_users changes
- Missing subscriptions in the channel view

## Behavior

### Initial Load
- When viewing a channel, the user list should show all users currently in the channel
- Users should be grouped by mode (operators, voiced, regular)
- The header should show the correct count

### Real-time Updates
- When a user joins, they should appear in the user list
- When a user leaves (part, quit, kick), they should be removed from the user list
- When a user's mode changes, they should move to the correct group
- The user count in the header should update

## Implementation Notes

1. First, fix the data key mismatch in `serialize_names_event` - change `users:` to `names:` to match what `handle_names` expects

2. Add Turbo Stream broadcasts for ChannelUser changes:
   - Broadcast to the channel's user list stream when users are added/removed
   - The channel view needs to subscribe to this stream

3. The user list partial at `app/views/channels/_user_list.html.erb` already has the correct structure - it just needs the data

## Tests

### Unit Tests - IrcEventHandler

**handle_names creates channel_users**
- Given: A channel exists
- When: A names event is received with ["@op_user", "+voiced_user", "regular_user"]
- Then: Three ChannelUser records are created with correct modes

**handle_names clears existing users first**
- Given: A channel has existing channel_users
- When: A names event is received
- Then: Old users are removed and new users are added

### Integration Tests

**Channel page shows user list**
- Given: A channel with 3 users (1 op, 1 voiced, 1 regular)
- When: User visits the channel page
- Then: The user list shows "3 users" and all three users in correct groups

**User list updates when user joins**
- Given: User is viewing a channel page
- When: A join event is received for a new user
- Then: The user list updates to include the new user (via Turbo Stream)

**User list updates when user parts**
- Given: User is viewing a channel page with multiple users
- When: A part event is received for a user
- Then: The user list updates to remove the user (via Turbo Stream)

## Dependencies

None - this is a bug fix for existing functionality.
