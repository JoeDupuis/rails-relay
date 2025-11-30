# Channel View

## Description

The main view for a channel, showing messages and allowing the user to participate.

## Behavior

### Layout

```
┌─────────────────────────────────────────────────────┐
│  Channel Header                                     │
│  #ruby · Welcome to #ruby - Ruby programming       │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Message List (scrollable)                          │
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │ [10:23] <alice> Hello everyone               │   │
│  │ [10:24] <bob> Hey alice!                     │   │
│  │ [10:25] * charlie waves                      │   │
│  │ [10:26] → joe joined                         │   │
│  │ [10:30] <alice> How's everyone doing?        │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
├─────────────────────────────────────────────────────┤
│  Message Input                                      │
│  [Type a message...                    ] [Send]     │
└─────────────────────────────────────────────────────┘
```

### Channel Header

- Channel name (#ruby)
- Channel topic (if set)
- User count (optional)
- Leave button

### Message List

Each message displays:
- Timestamp (HH:MM format, or full date if different day)
- Sender nickname
- Message content

Different styling for message types:
- **privmsg**: Normal message - `<nick> message`
- **action**: Italic/emphasized - `* nick does something`
- **notice**: Distinct color - `[notice] nick: message`
- **join**: System style - `→ nick joined`
- **part**: System style - `← nick left (reason)`
- **quit**: System style - `← nick quit (reason)`
- **kick**: System style - `nick was kicked by op (reason)`
- **topic**: System style - `nick changed topic to: new topic`
- **nick**: System style - `nick is now known as newnick`

### Message Input

- Text input field
- Send button (optional, Enter also sends)
- Placeholder: "Message #channel"
- Disabled if not connected

### User List (Sidebar)

When viewing a channel, the right sidebar shows:
- User count header
- List of users, grouped and sorted:
  1. Operators (@nick) - sorted alphabetically
  2. Voiced (+nick) - sorted alphabetically  
  3. Regular (nick) - sorted alphabetically

## Components

### channel-view

```css
.channel-view {
  display: flex;
  flex-direction: column;
  height: 100%;
  overflow: hidden;
  
  & > .header {
    flex-shrink: 0;
    padding: 12px 16px;
    border-bottom: 1px solid var(--color-border);
    display: flex;
    align-items: center;
    gap: 12px;
  }
  
  & > .header > .name {
    font-weight: 600;
    font-size: var(--font-lg);
  }
  
  & > .header > .topic {
    color: var(--color-text-muted);
    flex: 1;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  
  & > .messages {
    flex: 1;
    overflow-y: auto;
    padding: 16px;
  }
  
  & > .input {
    flex-shrink: 0;
    padding: 12px 16px;
    border-top: 1px solid var(--color-border);
  }
}
```

### message-item

```css
.message-item {
  --avatar-size: 0;  /* No avatars in IRC */
  --gap: 8px;
  --timestamp-width: 48px;
  
  display: flex;
  gap: var(--gap);
  padding: 2px 0;
  
  & > .timestamp {
    width: var(--timestamp-width);
    flex-shrink: 0;
    color: var(--color-text-muted);
    font-size: var(--font-sm);
  }
  
  & > .sender {
    font-weight: 600;
    flex-shrink: 0;
  }
  
  & > .content {
    flex: 1;
    word-break: break-word;
  }
  
  /* Message types */
  &.-action {
    font-style: italic;
    
    & > .sender::before { content: "* "; }
  }
  
  &.-notice {
    color: var(--color-text-muted);
    
    & > .sender::before { content: "[notice] "; }
  }
  
  &.-join,
  &.-part,
  &.-quit,
  &.-kick,
  &.-nick,
  &.-topic {
    color: var(--color-text-muted);
    font-size: var(--font-sm);
    
    & > .sender { font-weight: normal; }
  }
  
  &.-join > .content::before { content: "→ "; }
  &.-part > .content::before { content: "← "; }
  &.-quit > .content::before { content: "← "; }
  
  /* Own messages */
  &.-mine {
    & > .sender { color: var(--color-primary); }
  }
  
  /* Highlighted (contains our nick) */
  &.-highlight {
    background: var(--color-surface-raised);
    padding: 4px;
    margin: -4px;
    border-radius: var(--radius-sm);
  }
}
```

### message-input

```css
.message-input {
  display: flex;
  gap: 8px;
  
  & > .field {
    flex: 1;
    padding: 8px 12px;
    border: 1px solid var(--color-border);
    border-radius: var(--radius-md);
    font-size: var(--font-base);
  }
  
  & > .field:focus {
    outline: none;
    border-color: var(--color-primary);
  }
  
  & > .submit {
    padding: 8px 16px;
    background: var(--color-primary);
    color: white;
    border: none;
    border-radius: var(--radius-md);
    cursor: pointer;
  }
  
  & > .submit:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
}
```

### user-list

```css
.user-list {
  padding: 8px 0;
  
  & > .header {
    padding: 8px 12px;
    font-weight: 600;
    font-size: var(--font-sm);
    color: var(--color-text-muted);
  }
  
  & > .group {
    margin-bottom: 8px;
  }
  
  & > .group > .grouptitle {
    padding: 4px 12px;
    font-size: var(--font-sm);
    color: var(--color-text-muted);
  }
  
  & > .group > .users {
    list-style: none;
    padding: 0;
    margin: 0;
  }
}

.user-item {
  & > .nick {
    display: block;
    padding: 2px 12px;
    font-size: var(--font-sm);
  }
  
  &.-op > .nick::before { content: "@"; color: var(--color-success); }
  &.-voice > .nick::before { content: "+"; color: var(--color-primary); }
}
```

## View Structure

```erb
<%# app/views/channels/show.html.erb %>
<div class="channel-view" data-controller="channel">
  <header class="header">
    <span class="name"><%= @channel.name %></span>
    <span class="topic"><%= @channel.topic %></span>
    <%= link_to "Leave", channel_membership_path(@channel), 
        method: :delete, class: "leave" %>
  </header>
  
  <div class="messages" 
       data-controller="message-list"
       data-channel-target="messages">
    <div id="messages">
      <%= render @messages %>
    </div>
  </div>
  
  <div class="input">
    <%= render "messages/form", channel: @channel %>
  </div>
</div>

<% content_for :userlist do %>
  <%= render "channels/user_list", channel: @channel %>
<% end %>
```

```erb
<%# app/views/messages/_message.html.erb %>
<div class="message-item -<%= message.message_type %> 
     <%= '-mine' if message.from_me?(current_nickname) %>
     <%= '-highlight' if message.highlight?(current_nickname) %>"
     id="<%= dom_id(message) %>">
  <span class="timestamp"><%= message.created_at.strftime("%H:%M") %></span>
  <span class="sender"><%= message.sender %></span>
  <span class="content"><%= format_message(message) %></span>
</div>
```

```erb
<%# app/views/messages/_form.html.erb %>
<%= form_with url: channel_messages_path(channel), 
    class: "message-input",
    data: { controller: "message-form" } do |f| %>
  <%= f.text_field :content, 
      placeholder: "Message #{channel.name}",
      class: "field",
      data: { message_form_target: "input", action: "keydown.enter->message-form#submit" } %>
  <%= f.submit "Send", class: "submit" %>
<% end %>
```

```erb
<%# app/views/channels/_user_list.html.erb %>
<div class="user-list">
  <div class="header"><%= channel.channel_users.count %> users</div>
  
  <% if channel.channel_users.ops.any? %>
    <div class="group">
      <div class="grouptitle">Operators</div>
      <ul class="users">
        <% channel.channel_users.ops.order(:nickname).each do |u| %>
          <li class="user-item -op"><span class="nick"><%= u.nickname %></span></li>
        <% end %>
      </ul>
    </div>
  <% end %>
  
  <% if channel.channel_users.voiced.any? %>
    <div class="group">
      <div class="grouptitle">Voiced</div>
      <ul class="users">
        <% channel.channel_users.voiced.order(:nickname).each do |u| %>
          <li class="user-item -voice"><span class="nick"><%= u.nickname %></span></li>
        <% end %>
      </ul>
    </div>
  <% end %>
  
  <div class="group">
    <ul class="users">
      <% channel.channel_users.regular.order(:nickname).each do |u| %>
        <li class="user-item"><span class="nick"><%= u.nickname %></span></li>
      <% end %>
    </ul>
  </div>
</div>
```

## Helper

```ruby
# app/helpers/messages_helper.rb
module MessagesHelper
  def format_message(message)
    case message.message_type
    when "join"
      "#{message.sender} joined"
    when "part"
      "#{message.sender} left" + (message.content.present? ? " (#{message.content})" : "")
    when "quit"
      "#{message.sender} quit" + (message.content.present? ? " (#{message.content})" : "")
    when "kick"
      "#{message.sender} was kicked (#{message.content})"
    when "topic"
      "#{message.sender} changed topic to: #{message.content}"
    when "nick"
      "#{message.sender} is now known as #{message.content}"
    else
      message.content
    end
  end
  
  def current_nickname
    @channel&.server&.nickname
  end
end
```

## Tests

### System: Channel View

**Shows channel name and topic**
- Visit /channels/:id
- See channel name in header
- See topic in header

**Shows message list**
- Channel has messages
- Visit channel
- See messages displayed

**Message types styled differently**
- Channel has various message types
- Action messages italicized
- Join/part messages muted color

**Own messages highlighted**
- User sent messages in channel
- Those messages show sender in primary color

### System: User List

**Shows users grouped by mode**
- Channel has ops, voiced, regular users
- User list shows groups
- Ops first with @, voiced with +

**User count shown**
- Channel has 15 users
- Header shows "15 users"

### System: Message Input

**Can type and send message**
- Visit channel
- Type message
- Press Enter or click Send
- Message appears in list
- Input clears

### Integration: Real-time Messages

**New message appears without refresh**
- Viewing channel
- Message arrives via Turbo Stream
- Message appears at bottom

## Implementation Notes

- Message list should auto-scroll to bottom on new messages (if already at bottom)
- Consider lazy-loading user list for channels with many users
- Timestamps could show full date on hover
- Consider linkifying URLs in message content
- Consider showing message count or loading indicator during history fetch

## Dependencies

- Requires `ui-layout.md` (main layout)
- Requires `channels.md` (channel data)
- Requires `messages-receive.md` (messages exist)
- Requires `messages-history.md` (loading messages)
