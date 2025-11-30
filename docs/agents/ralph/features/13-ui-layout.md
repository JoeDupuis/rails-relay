# UI Layout

## Description

The main application layout with sidebar, content area, and responsive behavior.

## Behavior

### Desktop Layout (>= 1024px)

```
┌──────────────────────────────────────────────────────────────┐
│  Header: Logo, connection status, notifications, user menu   │
├─────────────┬────────────────────────────────┬───────────────┤
│             │                                │               │
│   Sidebar   │         Main Content           │   User List   │
│   (240px)   │         (flexible)             │   (180px)     │
│             │                                │   (optional)  │
│  - Servers  │  - Channel view                │               │
│  - Channels │  - Server view                 │  - Channel    │
│             │  - Settings                    │    members    │
│             │                                │               │
│             │                                │               │
├─────────────┴────────────────────────────────┴───────────────┤
│  (Input area is part of main content, not footer)            │
└──────────────────────────────────────────────────────────────┘
```

### Tablet Layout (768px - 1023px)

- Sidebar collapsible (hamburger menu)
- User list hidden by default (toggle button)
- Main content takes full width when sidebars hidden

### Mobile Layout (< 768px)

- Sidebar as overlay/drawer
- User list as overlay/drawer
- Single column, full width content
- Bottom navigation or hamburger

### Header

- Logo/app name (links to root)
- Connection status indicator (if any server disconnected)
- Notification bell with badge
- User dropdown (settings, sign out)

### Sidebar

Grouped by server:

```
▾ irc.libera.chat (●)
    # ruby (3)
    # rails
    # general
▾ irc.efnet.org (○)
    # music
```

- Server name with connection indicator (● connected, ○ disconnected)
- Channels indented under server
- Unread count badge on channels
- Click channel to view
- Click server to view server page

### Main Content Area

Changes based on route:
- `/servers/:id` - Server details, channel list, connect/disconnect
- `/channels/:id` - Channel messages, input
- `/servers/:id/pms/:nick` - PM conversation (future)
- `/settings` - User settings (future)

### User List (Channel View)

When viewing a channel:
- Shows users in that channel
- Grouped: Ops (@), Voiced (+), Regular
- Sorted alphabetically within groups
- Can be hidden/shown

## Components

### app-layout

Main layout wrapper:

```css
.app-layout {
  --sidebar-width: 240px;
  --userlist-width: 180px;
  --header-height: 48px;
  
  display: grid;
  grid-template-rows: var(--header-height) 1fr;
  grid-template-columns: var(--sidebar-width) 1fr var(--userlist-width);
  height: 100vh;
  
  & > .header {
    grid-column: 1 / -1;
  }
  
  & > .sidebar {
    grid-row: 2;
    overflow-y: auto;
  }
  
  & > .main {
    grid-row: 2;
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }
  
  & > .userlist {
    grid-row: 2;
    overflow-y: auto;
  }
  
  /* Tablet */
  @media (max-width: 1023px) {
    grid-template-columns: 1fr;
    
    & > .sidebar {
      position: fixed;
      /* drawer styles */
    }
    
    & > .userlist {
      display: none;
    }
  }
}
```

### app-header

```css
.app-header {
  --height: 48px;
  
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 0 16px;
  background: var(--color-surface);
  border-bottom: 1px solid var(--color-border);
  
  & > .logo {
    font-weight: 600;
  }
  
  & > .spacer {
    flex: 1;
  }
  
  & > .notifications {
    position: relative;
  }
  
  & > .usermenu {
    /* dropdown trigger */
  }
}
```

### channel-sidebar

```css
.channel-sidebar {
  padding: 8px 0;
  
  & > .servergroup {
    margin-bottom: 8px;
  }
  
  & > .servergroup > .servername {
    padding: 4px 12px;
    font-size: var(--font-sm);
    font-weight: 600;
    color: var(--color-text-muted);
    display: flex;
    align-items: center;
    gap: 8px;
  }
  
  & > .servergroup > .channels {
    list-style: none;
    padding: 0;
    margin: 0;
  }
}

.channel-item {
  & > .link {
    display: flex;
    align-items: center;
    padding: 4px 12px 4px 24px;
    color: var(--color-text);
    text-decoration: none;
  }
  
  & > .link:hover {
    background: var(--color-surface-raised);
  }
  
  & > .link > .badge {
    margin-left: auto;
    background: var(--color-primary);
    color: white;
    font-size: var(--font-sm);
    padding: 0 6px;
    border-radius: 9999px;
  }
  
  &.-unread > .link {
    font-weight: 600;
  }
  
  &.-active > .link {
    background: var(--color-primary);
    color: white;
  }
}
```

## View Structure

```erb
<%# app/views/layouts/application.html.erb %>
<!DOCTYPE html>
<html>
<head>...</head>
<body>
  <div class="app-layout">
    <header class="app-header">
      <%= render "shared/header" %>
    </header>
    
    <nav class="sidebar channel-sidebar">
      <%= render "shared/sidebar" %>
    </nav>
    
    <main class="main">
      <%= yield %>
    </main>
    
    <% if content_for?(:userlist) %>
      <aside class="userlist">
        <%= yield :userlist %>
      </aside>
    <% end %>
  </div>
</body>
</html>
```

```erb
<%# app/views/shared/_header.html.erb %>
<a href="<%= root_path %>" class="logo">IRC Client</a>
<div class="spacer"></div>
<div class="notifications" data-controller="notifications">
  <button class="bell">
    🔔
    <span class="notification-badge <%= 'hidden' if unread_notification_count.zero? %>">
      <%= unread_notification_count %>
    </span>
  </button>
</div>
<div class="usermenu">
  <%= current_user.email %>
  <%= button_to "Sign out", session_path, method: :delete %>
</div>
```

```erb
<%# app/views/shared/_sidebar.html.erb %>
<% current_user_servers.each do |server| %>
  <div class="servergroup">
    <div class="servername">
      <span class="indicator <%= server.connected? ? '-connected' : '-disconnected' %>"></span>
      <%= link_to server.address, server_path(server) %>
    </div>
    <ul class="channels">
      <% server.channels.each do |channel| %>
        <li class="channel-item <%= '-unread' if channel.unread? %> <%= '-active' if current_channel == channel %>">
          <%= link_to channel_path(channel), class: "link" do %>
            <%= channel.name %>
            <% if channel.unread_count > 0 %>
              <span class="badge"><%= channel.unread_count %></span>
            <% end %>
          <% end %>
        </li>
      <% end %>
    </ul>
  </div>
<% end %>
```

## Tests

### System: Layout Structure

**Desktop shows all three columns**
- Visit any page at desktop width
- Sidebar visible
- Main content visible
- User list visible (when applicable)

**Mobile shows hamburger menu**
- Visit at mobile width
- Sidebar hidden
- Hamburger button visible
- Click hamburger, sidebar appears

### System: Navigation

**Clicking channel navigates to channel**
- See sidebar with channels
- Click a channel
- URL changes to /channels/:id
- Channel content shown

**Logo links to root**
- Click logo
- Navigate to root path

### Integration: Sidebar Shows Servers and Channels

**Sidebar displays server groups**
- User has 2 servers with channels
- Sidebar shows both servers
- Each server has its channels listed

**Sidebar shows unread indicators**
- Channel has unread messages
- Sidebar shows badge with count

## Implementation Notes

- Use CSS Grid for layout, not flexbox hacks
- Sidebar should be Turbo Frame for real-time updates
- Mobile drawer can be CSS-only (checkbox hack) or Stimulus
- Consider using `content_for :userlist` in channel view to inject user list
- Test on actual devices, not just browser resize

## Dependencies

- Requires `auth-signin.md` (authenticated layout)
- Requires `server-crud.md` (servers to show)
- Requires `channels.md` (channels to show)
- Requires `notifications-unread.md` (unread badges)
