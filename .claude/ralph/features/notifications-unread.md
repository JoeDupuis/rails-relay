# Unread Tracking

## Description

The app tracks which messages the user has seen. Channels with unread messages are highlighted in the sidebar.

## Behavior

### What "Read" Means

A channel is considered "read" up to a certain message. The `last_read_message_id` on Channel tracks this.

- When user views a channel, mark it as read (update to latest message)
- Messages after `last_read_message_id` are "unread"

### Sidebar Display

For each channel in sidebar:
- Show unread indicator (dot, bold, highlight) if has unread messages
- Optionally show unread count badge

### Marking as Read

When user views a channel:
- Update `channel.last_read_message_id` to the latest message ID
- Remove unread indicator from sidebar

This should happen:
- On page load (visiting channel)
- When new messages arrive while viewing (if at bottom of scroll)

### Unread Count

```ruby
class Channel < ApplicationRecord
  def unread_count
    return 0 unless last_read_message_id
    messages.where("id > ?", last_read_message_id).count
  end
  
  def unread?
    if last_read_message_id
      messages.where("id > ?", last_read_message_id).exists?
    else
      messages.exists?
    end
  end
  
  def mark_as_read!
    update!(last_read_message_id: messages.maximum(:id))
  end
end
```

### New Channel

When joining a new channel:
- `last_read_message_id` is nil
- All existing messages (from backlog) could show as unread
- Or: set `last_read_message_id` to current max on join

Decision: Set to current max on join (user is "caught up" when they join).

### Real-time Sidebar Updates

When a message arrives for a channel the user is NOT viewing:
- Sidebar should update to show unread indicator
- Use Turbo Stream broadcast to sidebar frame

## Controller

```ruby
# app/controllers/channels_controller.rb
class ChannelsController < ApplicationController
  def show
    @channel = Channel.find(params[:id])
    @channel.mark_as_read!
    @messages = @channel.messages.order(created_at: :desc).limit(50).reverse
  end
end
```

### Sidebar Partial

```erb
<%# app/views/shared/_sidebar.html.erb %>
<nav class="sidebar">
  <% current_user_servers.each do |server| %>
    <div class="server-group">
      <h3><%= server.address %></h3>
      <ul class="channel-list">
        <% server.channels.each do |channel| %>
          <li class="channel-item <%= '-unread' if channel.unread? %>">
            <%= link_to channel.name, channel_path(channel) %>
            <% if channel.unread_count > 0 %>
              <span class="badge"><%= channel.unread_count %></span>
            <% end %>
          </li>
        <% end %>
      </ul>
    </div>
  <% end %>
</nav>
```

### Broadcasting Sidebar Updates

When a message is created, broadcast sidebar update:

```ruby
class Message < ApplicationRecord
  after_create_commit :broadcast_message, :broadcast_sidebar_update
  
  private
  
  def broadcast_sidebar_update
    return unless channel
    
    # Broadcast to user's sidebar stream
    broadcast_replace_to(
      [server.user, :sidebar],
      target: "channel_#{channel.id}_sidebar",
      partial: "shared/channel_sidebar_item",
      locals: { channel: channel }
    )
  end
end
```

## Tests

### Model: Channel#unread_count

**returns 0 when last_read_message_id is nil and no messages**

**returns count of all messages when last_read_message_id is nil**
- Or returns 0 if we set last_read on join (per decision above)

**returns count of messages after last_read_message_id**
- Channel has 10 messages, last_read is message 5
- unread_count returns 5

**returns 0 when fully read**
- last_read_message_id equals latest message
- unread_count returns 0

### Model: Channel#unread?

**returns false when no messages**
**returns true when has unread messages**
**returns false when fully read**

### Model: Channel#mark_as_read!

**updates last_read_message_id to max message id**
**makes unread? return false**

### Controller: ChannelsController#show

**marks channel as read on view**
- Channel has unread messages
- GET /channels/:id
- Channel.last_read_message_id updated
- Channel.unread? now false

### Integration: Unread Indicators

**Sidebar shows unread indicator**
- User has channel with unread messages
- View sidebar (any page)
- Channel shows unread indicator/badge

**Viewing channel clears unread**
- Channel shows unread in sidebar
- Visit channel
- Unread indicator gone

**New message updates sidebar**
- User viewing channel A
- Message arrives in channel B
- Channel B shows unread in sidebar (without refresh)

## Implementation Notes

- Sidebar can be a Turbo Frame that receives broadcasts
- Consider caching unread counts if performance is an issue
- For PMs: similar tracking, but on what? Could use a separate model or track per-target
- `last_read_message_id` approach is simple but means we can't mark individual messages

## Dependencies

- Requires `channels.md` (Channel model)
- Requires `messages-receive.md` (Messages being created)
