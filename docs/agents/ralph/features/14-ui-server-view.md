# Server View

## Description

The page showing a single server's details, connection status, and channels.

## Behavior

### Layout

```
┌─────────────────────────────────────────────────────┐
│  Server Header                                       │
│  irc.libera.chat:6697 (SSL)           [Connected ●] │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Connection Actions                                 │
│  [Disconnect]  [Edit Server]  [Delete Server]       │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Join Channel                                       │
│  [#channel-name        ] [Join]                     │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Channels (3)                                       │
│  ┌─────────────────────────────────────────────┐   │
│  │ #ruby           12 users    [View] [Leave]  │   │
│  │ #rails          45 users    [View] [Leave]  │   │
│  │ #general         8 users    [View] [Leave]  │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Server Messages (collapsible)                      │
│  [Show server messages ▼]                           │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Server Info

Display:
- Address and port
- SSL indicator
- Nickname we're using
- Connection status (connected/disconnected/connecting)
- Connected since (if connected)

### Connection Actions

**When disconnected:**
- Connect button

**When connected:**
- Disconnect button

Always:
- Edit Server link
- Delete Server link (with confirmation)

### Join Channel

- Input field for channel name
- Prefill with # if user doesn't type it
- Join button
- Only visible when connected

### Channel List

- List of channels we've joined on this server
- Each shows: name, user count, View link, Leave link
- Click name or View to go to channel

### Server Messages

- Collapsible section showing server messages (MOTD, etc.)
- Messages where channel_id is null and target is null
- Useful for debugging connection issues

## Controller

```ruby
# app/controllers/servers_controller.rb
class ServersController < ApplicationController
  def show
    @server = Server.find(params[:id])
    @channels = @server.channels.order(:name)
    @server_messages = @server.messages
                              .where(channel_id: nil, target: nil)
                              .order(created_at: :desc)
                              .limit(100)
  end
end
```

## View

```erb
<%# app/views/servers/show.html.erb %>
<div class="server-view">
  <header class="server-header">
    <div class="info">
      <h1 class="address"><%= @server.address %>:<%= @server.port %></h1>
      <% if @server.ssl %>
        <span class="badge -ssl">SSL</span>
      <% end %>
    </div>
    <div class="status">
      <% if @server.connected? %>
        <span class="indicator -connected">● Connected</span>
        <span class="since">since <%= @server.connected_at.strftime("%b %d %H:%M") %></span>
      <% else %>
        <span class="indicator -disconnected">○ Disconnected</span>
      <% end %>
    </div>
  </header>
  
  <section class="actions">
    <% if @server.connected? %>
      <%= button_to "Disconnect", server_connection_path(@server), method: :delete, class: "button -danger" %>
    <% else %>
      <%= button_to "Connect", server_connection_path(@server), method: :post, class: "button -primary" %>
    <% end %>
    
    <%= link_to "Edit", edit_server_path(@server), class: "button" %>
    <%= button_to "Delete", server_path(@server), method: :delete, 
        data: { confirm: "Delete this server and all its history?" }, 
        class: "button -danger" %>
  </section>
  
  <% if @server.connected? %>
    <section class="join-channel">
      <h2>Join Channel</h2>
      <%= form_with url: server_channels_path(@server), class: "join-form" do |f| %>
        <%= f.text_field :name, placeholder: "#channel", class: "field" %>
        <%= f.submit "Join", class: "button -primary" %>
      <% end %>
    </section>
  <% end %>
  
  <section class="channels">
    <h2>Channels (<%= @channels.count %>)</h2>
    <% if @channels.any? %>
      <ul class="channel-list">
        <% @channels.each do |channel| %>
          <li class="channel-row">
            <span class="name"><%= channel.name %></span>
            <span class="users"><%= channel.channel_users.count %> users</span>
            <span class="actions">
              <%= link_to "View", channel_path(channel), class: "link" %>
              <%= button_to "Leave", channel_path(channel), method: :delete, class: "link -danger" %>
            </span>
          </li>
        <% end %>
      </ul>
    <% else %>
      <p class="empty">No channels yet. Join one above.</p>
    <% end %>
  </section>
  
  <section class="server-messages">
    <details>
      <summary>Server Messages</summary>
      <div class="messages">
        <% @server_messages.each do |msg| %>
          <div class="server-message">
            <span class="time"><%= msg.created_at.strftime("%H:%M:%S") %></span>
            <span class="content"><%= msg.content %></span>
          </div>
        <% end %>
      </div>
    </details>
  </section>
</div>
```

## Components CSS

```css
.server-view {
  padding: 24px;
  max-width: 800px;
}

.server-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 24px;
  
  & > .info > .address {
    font-size: var(--font-xl);
    margin: 0 0 4px 0;
  }
  
  & > .status > .indicator {
    font-weight: 500;
    
    &.-connected { color: var(--color-success); }
    &.-disconnected { color: var(--color-text-muted); }
  }
  
  & > .status > .since {
    color: var(--color-text-muted);
    font-size: var(--font-sm);
    margin-left: 8px;
  }
}

.server-view > section {
  margin-bottom: 32px;
  
  & > h2 {
    font-size: var(--font-lg);
    margin: 0 0 12px 0;
  }
}

.join-form {
  display: flex;
  gap: 8px;
  
  & > .field {
    width: 200px;
  }
}

.channel-row {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 8px 0;
  border-bottom: 1px solid var(--color-border);
  
  & > .name {
    font-weight: 500;
    min-width: 150px;
  }
  
  & > .users {
    color: var(--color-text-muted);
    font-size: var(--font-sm);
  }
  
  & > .actions {
    margin-left: auto;
    display: flex;
    gap: 12px;
  }
}

.server-messages {
  & > details > summary {
    cursor: pointer;
    color: var(--color-text-muted);
  }
  
  & > details > .messages {
    max-height: 300px;
    overflow-y: auto;
    background: var(--color-surface-raised);
    padding: 12px;
    margin-top: 8px;
    font-family: monospace;
    font-size: var(--font-sm);
  }
}
```

## Tests

### Controller: ServersController#show

**GET /servers/:id**
- Returns 200
- Shows server info
- Shows channels

**Shows connection status**
- Server is connected
- Page shows "Connected" with indicator

**Shows channels list**
- Server has 3 channels
- All 3 displayed with names

### Integration: Server Page

**User views server details**
- Visit /servers/:id
- See address, port, SSL status
- See connection status

**User can connect from server page**
- Server is disconnected
- Click Connect
- Server connects (or starts connecting)

**User can join channel from server page**
- Server is connected
- Enter channel name
- Click Join
- Channel appears in list

### System: Server Management Flow

**Full server workflow**
- Add server
- Connect to server
- Join channel
- View channel
- Leave channel
- Disconnect
- Delete server

## Implementation Notes

- Connect/disconnect actions handled by ConnectionsController (from `05-irc-connections.md`)
- Join handled by ChannelsController (from `06-channels.md`)
- Server messages section helps debug connection issues
- Consider Turbo Stream updates for connection status changes

## Dependencies

- Requires `03-server-crud.md` (Server model and CRUD)
- Requires `05-irc-connections.md` (connection actions)
- Requires `06-channels.md` (channel list and joining)
