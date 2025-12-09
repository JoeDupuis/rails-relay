# DM User Online/Offline Status

## Description

Currently there's no way to see if a DM user is online or offline. This feature adds a presence indicator to DM items in the sidebar showing whether the user is currently visible on the IRC server (i.e., you share at least one channel with them).

## How IRC Presence Works

In IRC, you can only see users who are in channels you've joined. There's no global "online" list. So "online" for our purposes means: **the target_nick exists in at least one ChannelUser record on the same server**.

This is a reasonable approximation:
- If you share a channel → you can see them → they're "online"
- If you don't share any channels → you can't see them → they're "offline" (or just not visible to you)

## Behavior

### Sidebar DM Items

Each DM item in the sidebar shows an online/offline indicator next to the username:
- **Online**: Green dot (same style as server connection indicator)
- **Offline**: Gray/dim dot or no indicator

### Determining Online Status

Add a method to Conversation model:

```ruby
def target_online?
  server.channel_users.exists?(nickname: target_nick)
end
```

This checks if the target_nick appears in ANY channel on that server that the user has joined.

### Live Updates

When a user joins or leaves a channel, their online status in DM sidebar should update:
- User joins a channel you're in → if you have a DM with them, indicator turns green
- User leaves all shared channels (part/quit) → indicator turns gray

This requires broadcasting sidebar updates when ChannelUser records change.

### Broadcast Strategy

ChannelUser already broadcasts to update the user list. Additionally, when a ChannelUser is created/destroyed, check if there's a Conversation with that nickname and broadcast a sidebar update.

In `ChannelUser` callbacks:
```ruby
after_create_commit :broadcast_dm_presence_change
after_destroy_commit :broadcast_dm_presence_change

def broadcast_dm_presence_change
  conversation = Conversation.find_by(server: channel.server, target_nick: nickname)
  return unless conversation
  conversation.broadcast_sidebar_update
end
```

Note: Need to make `broadcast_sidebar_update` public or create a public wrapper.

## Models

### Conversation

Add method:
```ruby
def target_online?
  server.channel_users.exists?(nickname: target_nick)
end
```

Make sidebar broadcast callable from outside (or add public method):
```ruby
def broadcast_presence_update
  broadcast_sidebar_update
end
```

### ChannelUser

Add callbacks to notify DM sidebar of presence changes:
```ruby
after_create_commit :notify_dm_presence
after_destroy_commit :notify_dm_presence

private

def notify_dm_presence
  conversation = Conversation.find_by(server: channel.server, target_nick: nickname)
  conversation&.broadcast_presence_update
end
```

### Server

Add helper to check if a nick is visible:
```ruby
def nick_online?(nickname)
  channel_users.exists?(nickname: nickname)
end
```

## Views

### `shared/_conversation_sidebar_item.html.erb`

Add presence indicator:
```erb
<li id="conversation_<%= conversation.id %>_sidebar" class="dm-item <%= '-unread' if conversation.unread? %> <%= '-active' if current_conversation == conversation %>">
  <span class="presence-indicator <%= conversation.target_online? ? '-online' : '-offline' %>"></span>
  <%= link_to conversation_path(conversation), class: "link" do %>
    <%= conversation.target_nick %>
    <% if conversation.unread_count > 0 %>
      <span class="badge"><%= conversation.unread_count %></span>
    <% end %>
  <% end %>
</li>
```

### CSS

Add styles for presence indicator (can reuse connection-indicator pattern):
```css
.dm-item .presence-indicator {
  /* small dot before nickname */
}

.dm-item .presence-indicator.-online {
  /* green dot */
}

.dm-item .presence-indicator.-offline {
  /* gray dot or hidden */
}
```

## Tests

### Model Tests

**Conversation#target_online? returns true when user is in a shared channel**
- Given: server with channel "#ruby"
- And: channel has ChannelUser with nickname "alice"
- And: conversation with target_nick "alice"
- When: calling conversation.target_online?
- Then: returns true

**Conversation#target_online? returns false when user is not in any channel**
- Given: server with channel "#ruby"
- And: channel has no ChannelUser with nickname "bob"
- And: conversation with target_nick "bob"
- When: calling conversation.target_online?
- Then: returns false

**Conversation#target_online? is case-sensitive (IRC nicks are case-insensitive)**
- Given: conversation with target_nick "Alice"
- And: ChannelUser exists with nickname "alice"
- When: calling conversation.target_online?
- Then: returns true (need case-insensitive check)

Note: IRC nicknames are case-insensitive. The query should use case-insensitive matching.

**Server#nick_online? helper**
- Given: server with ChannelUser "alice" in some channel
- When: calling server.nick_online?("alice")
- Then: returns true

### Integration Tests

**ChannelUser creation broadcasts DM sidebar update**
- Given: existing conversation with target_nick "alice"
- When: ChannelUser is created with nickname "alice"
- Then: broadcasts replace to sidebar stream with updated conversation item

**ChannelUser destruction broadcasts DM sidebar update**
- Given: existing conversation with target_nick "alice"
- And: ChannelUser exists with nickname "alice"
- When: ChannelUser is destroyed
- Then: broadcasts replace to sidebar stream with updated conversation item

### System Tests

**DM shows online indicator when user is in shared channel**
- Given: logged in user with server
- And: joined channel "#ruby" with user "alice" present
- And: existing DM conversation with "alice"
- When: viewing sidebar
- Then: DM item for "alice" shows green online indicator

**DM shows offline indicator when user is not in any channel**
- Given: logged in user with server
- And: existing DM conversation with "bob"
- And: "bob" is not in any joined channels
- When: viewing sidebar
- Then: DM item for "bob" shows gray/no indicator

**Indicator updates live when user joins channel**
- Given: viewing sidebar with offline DM for "alice"
- When: "alice" joins a channel you're in (simulated via ChannelUser creation)
- Then: DM indicator changes to online without page refresh

**Indicator updates live when user leaves all channels**
- Given: viewing sidebar with online DM for "alice"
- And: "alice" is only in one shared channel
- When: "alice" leaves that channel (ChannelUser destroyed)
- Then: DM indicator changes to offline without page refresh

## Implementation Notes

- IRC nicknames are case-insensitive. Use `LOWER()` or Rails' `where` with `ILIKE` (Postgres) or handle in Ruby
- The ChannelUser nickname is stored as received from IRC (may have varying case)
- Conversation target_nick is also stored as received
- For SQLite (dev/test), use `LOWER(nickname) = LOWER(?)` pattern
- Consider debouncing if there are many rapid ChannelUser changes (e.g., netsplit)
- The presence indicator CSS should match the existing connection-indicator style for consistency

## Dependencies

None - uses existing ChannelUser and Conversation models.
