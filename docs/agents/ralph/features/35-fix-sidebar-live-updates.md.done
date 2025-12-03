# Fix Sidebar Live Updates

## Description

The sidebar doesn't update in real-time when:
1. A new DM conversation is created (someone DMs you)
2. A channel is joined
3. A conversation is started via `/msg` command

Leaving a channel works correctly because `Channel#broadcast_joined_status` triggers on `joined` changing to `false`, but the broadcast goes to the server show page, not the sidebar.

## Root Causes

### 1. Turbo Stream name mismatch
- Sidebar subscribes to: `sidebar_#{Current.user.id}`
- Message model broadcasts to: `user_#{Current.user_id}_sidebar`
- These are different stream names!

### 2. Channel join doesn't broadcast to sidebar
- `Channel#broadcast_joined_status` broadcasts to the server show page (`servers/channels` partial)
- It does NOT broadcast to the user's sidebar

### 3. Conversation has no broadcasts
- `Conversation` model has no `after_create_commit` or other broadcasts
- When a new DM conversation is created, the sidebar doesn't know about it

## Behavior

### New DM conversation
- When someone sends you a DM for the first time (new Conversation created)
- The DM should immediately appear in the sidebar under that server's "DMs" section

### Channel joined
- When a channel's `joined` status changes to `true`
- The channel should immediately appear in the sidebar under that server's "Channels" section

### Channel left
- When a channel's `joined` status changes to `false`
- The channel should immediately disappear from the sidebar

### Unread count updates (already partially working)
- When a message is received, the unread count badge should update
- Note: This requires fixing the stream name mismatch

## Implementation

### 1. Fix stream name in Message model

In `app/models/message.rb`, change the broadcast target:

```ruby
def broadcast_sidebar_update
  return unless channel
  return unless Current.user_id

  broadcast_replace_to(
    "sidebar_#{Current.user_id}",  # Was: "user_#{Current.user_id}_sidebar"
    target: "channel_#{channel.id}_sidebar",
    partial: "shared/channel_sidebar_item",
    locals: { channel: channel }
  )
end
```

### 2. Add sidebar broadcast to Channel model

When `joined` changes, broadcast to sidebar to add/remove the channel:

```ruby
after_update_commit :broadcast_sidebar_joined_status, if: :saved_change_to_joined?

private

def broadcast_sidebar_joined_status
  return unless server.user_id

  if joined?
    broadcast_append_to(
      "sidebar_#{server.user_id}",
      target: "server_#{server.id}_channels",
      partial: "shared/channel_sidebar_item",
      locals: { channel: self }
    )
  else
    broadcast_remove_to(
      "sidebar_#{server.user_id}",
      target: "channel_#{id}_sidebar"
    )
  end
end
```

### 3. Update sidebar view with channel list target

In `app/views/shared/_sidebar.html.erb`, add an ID to the channel list for targeting:

```erb
<ul class="channels" id="server_<%= server.id %>_channels">
  <% server.channels.joined.each do |channel| %>
    <%= render "shared/channel_sidebar_item", channel: channel %>
  <% end %>
</ul>
```

### 4. Add Conversation broadcasts

In `app/models/conversation.rb`:

```ruby
after_create_commit :broadcast_sidebar_add
after_update_commit :broadcast_sidebar_update, if: :saved_change_to_last_message_at?

private

def broadcast_sidebar_add
  return unless server.user_id

  broadcast_append_to(
    "sidebar_#{server.user_id}",
    target: "server_#{server.id}_dms",
    partial: "shared/conversation_sidebar_item",
    locals: { conversation: self }
  )
end

def broadcast_sidebar_update
  return unless server.user_id

  broadcast_replace_to(
    "sidebar_#{server.user_id}",
    target: "conversation_#{id}_sidebar",
    partial: "shared/conversation_sidebar_item",
    locals: { conversation: self }
  )
end
```

### 5. Update sidebar view with DM list target

In `app/views/shared/_sidebar.html.erb`, add an ID to the DM list:

```erb
<% if server.conversations.any? %>
  <div class="section-label">DMs</div>
  <ul class="dm-list" id="server_<%= server.id %>_dms">
    <% server.conversations.order(last_message_at: :desc).each do |convo| %>
      <%= render "shared/conversation_sidebar_item", conversation: convo %>
    <% end %>
  </ul>
<% else %>
  <ul class="dm-list" id="server_<%= server.id %>_dms" style="display: none;"></ul>
<% end %>
```

Note: The empty list with `display: none` is needed so Turbo has a target to append to when the first DM is created.

### 6. Show DMs section label when first DM created

The "DMs" section label should appear when the first conversation is created. Options:
- Include the label in the conversation partial with conditional display
- Or broadcast a replace to a wrapper div that includes both label and list

Simplest approach: Always render the section structure, hide when empty via CSS:

```erb
<div class="dm-section" id="server_<%= server.id %>_dm_section">
  <div class="section-label">DMs</div>
  <ul class="dm-list" id="server_<%= server.id %>_dms">
    <% server.conversations.order(last_message_at: :desc).each do |convo| %>
      <%= render "shared/conversation_sidebar_item", conversation: convo %>
    <% end %>
  </ul>
</div>
```

CSS:
```css
.dm-section:has(.dm-list:empty) {
  display: none;
}
```

## Tests

### System Tests

**New DM appears in sidebar**
- Given: User is on any page
- When: Another user sends them a DM (new Conversation created via IrcEventHandler)
- Then: DM appears in sidebar under the server's "DMs" section without page refresh

**Channel join appears in sidebar**
- Given: User is on the server show page
- When: User joins a channel
- Then: Channel appears in sidebar "Channels" section without refresh

**Channel leave removes from sidebar**
- Given: User has joined #test channel
- When: User leaves/parts #test
- Then: #test disappears from sidebar without refresh

**Unread count updates**
- Given: User is viewing #general
- When: Message arrives in #other channel
- Then: #other shows unread badge in sidebar

### Model Tests

**Message#broadcast_sidebar_update stream name**
- Given: Message created in a channel
- Then: Broadcasts to `sidebar_#{user.id}` (not `user_#{user.id}_sidebar`)

**Channel sidebar broadcast on join**
- Given: Channel with `joined: false`
- When: Channel is updated to `joined: true`
- Then: Broadcasts append to `sidebar_#{user.id}`

**Conversation broadcast on create**
- Given: New Conversation is created
- Then: Broadcasts append to `sidebar_#{user.id}`

## Dependencies

None - this is a bugfix for existing functionality.
