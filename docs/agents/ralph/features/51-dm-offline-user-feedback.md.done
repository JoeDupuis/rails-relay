# DM Offline User Feedback

## Description

Users can open DM conversations with offline users, but there's no visual feedback that the target is offline. The chat input should be disabled/grayed out similar to how it appears when not connected to a channel.

## Current Behavior

1. User opens DM with someone who is offline
2. Chat input is fully enabled
3. User can type and send messages
4. No indication that the recipient is offline (other than sidebar presence indicator)
5. Messages sent may not be received if user is truly offline

## Expected Behavior

1. When viewing a DM with an offline user:
   - The message input should be disabled/grayed out
   - A message should indicate the user is offline
   - Same visual treatment as "not joined to channel" state
2. When the user comes online:
   - Input should become enabled via Turbo Stream
   - User can send messages normally

## Current Form Logic

In `app/views/messages/_form.html.erb`:

```ruby
can_send = messageable.server.connected? && (!is_channel || messageable.joined)
```

For conversations, `is_channel` is false, so this becomes:
```ruby
can_send = messageable.server.connected?
```

This doesn't check if the DM target is online.

## Files to Modify

- `app/views/messages/_form.html.erb` - Add offline user check
- `app/models/conversation.rb` - Add broadcast when online status changes (may already exist)
- `app/views/channels/_input.html.erb` - Add Turbo target for live updates

## Implementation

### Update Form Logic

```ruby
<% is_channel = messageable.is_a?(Channel) %>
<% is_conversation = messageable.is_a?(Conversation) %>
<% target_offline = is_conversation && !messageable.online? %>
<% can_send = messageable.server.connected? && (!is_channel || messageable.joined) && !target_offline %>

<% if can_send %>
  <%# ... existing form ... %>
<% elsif target_offline %>
  <div class="message-input">
    <span class="disabled"><%= messageable.target_nick %> is offline.</span>
  </div>
<% elsif is_channel && messageable.server.connected? && !messageable.joined %>
  <%# ... existing not joined state ... %>
<% else %>
  <%# ... existing not connected state ... %>
<% end %>
```

### Live Updates

The input partial needs to update when the DM user's online status changes. The conversation model already has `broadcast_presence_update` which updates the sidebar item.

Add a broadcast to update the input area as well:

```ruby
# In Conversation model
def broadcast_input_update
  broadcast_replace_to(
    [server, :dm, target_nick.downcase],
    target: dom_id(self, :input),
    partial: "channels/input",
    locals: { messageable: self }
  )
end
```

Call this in the same places where `broadcast_presence_update` is called.

### ISON Updates

The `IsonsController` updates conversation online status. After updating, it should trigger input updates for affected conversations.

Currently, the ISON turbo stream view re-renders sidebar items. It should also re-render input if the user is viewing that conversation.

## Tests

### Controller Tests

**conversation show with offline user shows disabled input**
- Given: Conversation with online: false
- When: GET /conversations/:id
- Then: Response includes disabled input with offline message

**conversation show with online user shows enabled input**
- Given: Conversation with online: true
- When: GET /conversations/:id
- Then: Response includes full message form

### Integration Tests

**offline status change updates input area**
- Given: User viewing conversation
- When: Conversation's online status changes to false
- Then: Turbo Stream updates input to disabled state

**online status change enables input area**
- Given: User viewing conversation with offline target
- When: Conversation's online status changes to true
- Then: Turbo Stream updates input to enabled form

### System Tests

**DM with offline user shows disabled input**
1. Sign in
2. Create/open conversation with user
3. Mark conversation as offline (via internal API or direct DB update)
4. Navigate to conversation
5. Verify input shows "X is offline." message
6. Verify input field is not present/disabled

**DM input enables when user comes online**
1. Sign in
2. Navigate to conversation with offline user
3. Verify disabled input
4. Trigger online status update (via ISON response)
5. Verify input becomes enabled without page refresh

**Can still view messages with offline user**
1. Sign in
2. Navigate to conversation with offline user
3. Verify message history is still visible
4. Only input area is disabled

## Dependencies

- 40-dm-user-online-status.md.done (online/offline tracking)
- 41-close-dm-conversations.md.done (conversation model updates)

## Implementation Notes

- The conversation's `online?` method delegates to `online` boolean column
- ISON polling updates this column periodically
- When user receives DM, they're marked online (IrcEventHandler)
- When "no such nick" error, they're marked offline
- The disabled state should match the visual treatment of "not joined to channel"
- Consider adding a "Send anyway" option for power users who know IRC semantics (messages queue on server), but keep simple for MVP
- The Turbo Stream subscription already exists: `turbo_stream_from [ @server, :dm, @conversation.target_nick.downcase ]`
