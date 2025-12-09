# Unify User List Partial (Desktop/Mobile)

## Description

Currently the user list is rendered twice in the HTML:
1. **Desktop**: In `<aside class="userlist">` via `content_for :userlist` in layout
2. **Mobile**: Inside `channels/_header.html.erb` in a `.userlist-drawer` element

This causes two problems:
1. HTML duplication - same content rendered twice
2. Turbo Stream broadcasts only update the desktop version (target: `channel_#{id}_user_list`), so mobile drawer doesn't get live updates

The fix: render the user list once, use CSS to display it as a permanent sidebar on desktop and as a slide-in drawer on mobile.

## Current Architecture

**Desktop (≥1024px)**:
- Layout has `<aside class="userlist">` as third grid column
- Channel view does `content_for :userlist` to populate it
- User list always visible

**Mobile (<1024px)**:
- Layout hides `<aside class="userlist">` with `display: none`
- Header has duplicate user list in `.userlist-drawer`
- Button in header opens drawer
- Drawer slides in from right

**Turbo Broadcasts**:
- ChannelUser broadcasts to target `channel_#{id}_user_list`
- Only the desktop `<aside>` version has this ID
- Mobile drawer never receives updates

## Target Architecture

**Single user list element** that:
- On desktop: displays as permanent right sidebar (grid column)
- On mobile: hidden by default, slides in as drawer when triggered
- Same element receives Turbo Stream updates in both modes

**Structure**:
```
<aside class="userlist" id="channel_#{id}_user_list">
  <!-- user list header and content -->
  <!-- close button visible only on mobile -->
</aside>
```

**CSS handles the responsive behavior**:
- Desktop: part of grid, always visible
- Mobile: fixed position, transformed off-screen, slides in when open

## Behavior

### Desktop (≥1024px)

- User list visible as right sidebar (current behavior)
- No open/close controls needed
- Live updates via Turbo Stream work

### Mobile (<1024px)

- User list hidden off-screen to the right
- Button in channel header opens it (adds `-open` class)
- Backdrop appears behind drawer
- Click backdrop or press Escape to close
- Close button (×) inside drawer header
- Live updates via Turbo Stream work (same element)

### Toggle Button

The toggle button in the header should:
- Only appear on mobile (hidden on desktop via CSS)
- Show user count
- Trigger the drawer to open

Currently this button is inside `_header.html.erb`. It should remain there but control the layout's `<aside class="userlist">` instead of a duplicate drawer.

## Implementation

### 1. Remove Duplicate User List from Header

In `channels/_header.html.erb`, remove:
- The `.userlist-backdrop` element
- The `.userlist-drawer` element and its contents
- Keep the `.userlist-toggle` button

### 2. Modify Layout User List

In `application.html.erb`, the `<aside class="userlist">` needs:
- Close button (visible only on mobile)
- Header with title
- Backdrop element (for mobile)

Or better: modify the `channels/_user_list.html.erb` partial to include drawer chrome (header with close button) that's hidden on desktop.

### 3. Add Drawer Behavior to Layout User List

The `userlist-drawer` Stimulus controller currently targets elements inside the header. Modify it to:
- Control the layout's `<aside class="userlist">` element
- Add backdrop to layout (or use existing sidebar backdrop pattern)

### 4. CSS Changes

**`app-layout.css`** - Remove `display: none` for userlist on mobile, instead use transform:
```css
@media (max-width: 1023px) {
  & > .userlist {
    position: fixed;
    top: var(--header-height);
    right: 0;
    bottom: 0;
    width: 240px;
    transform: translateX(100%);
    transition: transform 0.2s ease;
    z-index: 200;
  }

  & > .userlist.-open {
    transform: translateX(0);
  }
}
```

**`userlist-drawer.css`** - Can be removed or repurposed for the unified styling.

### 5. Stimulus Controller

The `userlist_drawer_controller` needs to:
- Be attached to a parent element that can reach both the toggle button and the userlist
- Target the layout's `<aside class="userlist">`
- Handle backdrop visibility

Options:
A. Attach controller to channel view container, use outlet to reach userlist
B. Attach controller to layout, use global selector
C. Use a new controller on the layout that listens to custom events

Recommended: **Option A with outlet** - The channel view already has a controller. Add an outlet that references the layout's userlist.

### 6. User List Partial Structure

Modify `channels/_user_list.html.erb` to include mobile-only chrome:
```erb
<aside id="channel_<%= channel.id %>_user_list" class="userlist">
  <div class="drawer-header">
    <span class="title">Users (<%= channel.channel_users.size %>)</span>
    <button class="close" data-action="userlist-drawer#close">&times;</button>
  </div>
  <div class="content">
    <%= render "channels/user_list_content", channel: channel %>
  </div>
</aside>
```

The `.drawer-header` and `.close` button are hidden on desktop via CSS.

Wait - the user list is rendered via `content_for :userlist`. So the partial structure works, but we need to ensure the controller can reach it.

## Detailed Implementation Steps

### Step 1: Update `channels/_user_list.html.erb`

Change from:
```erb
<div id="channel_<%= channel.id %>_user_list" class="user-list">
  <div class="header"><%= channel.channel_users.size %> users</div>
  <%= render "channels/user_list_content", channel: channel %>
</div>
```

To:
```erb
<div id="channel_<%= channel.id %>_user_list" class="user-list" data-userlist-drawer-target="drawer">
  <div class="drawer-header">
    <span class="title"><%= channel.channel_users.size %> users</span>
    <button class="close" data-action="userlist-drawer#close" aria-label="Close user list">&times;</button>
  </div>
  <div class="content">
    <%= render "channels/user_list_content", channel: channel %>
  </div>
</div>
```

### Step 2: Update `channels/_header.html.erb`

Remove the duplicate drawer and backdrop. Keep only:
```erb
<header class="header" id="<%= dom_id(channel, :header) %>">
  <!-- ... existing name, topic, buttons ... -->

  <button class="userlist-toggle" data-action="userlist-drawer#open" aria-label="Show user list">
    <span class="icon">&#128101;</span>
    <span class="count"><%= channel.channel_users.size %></span>
  </button>
</header>
```

### Step 3: Add Backdrop to Layout

In `application.html.erb`, add backdrop inside the app-layout div:
```erb
<div class="app-layout ..." data-controller="userlist-drawer">
  <!-- ... header, sidebar, main ... -->

  <% if content_for?(:userlist) %>
    <div class="userlist-backdrop" data-userlist-drawer-target="backdrop" data-action="click->userlist-drawer#backdropClick"></div>
    <aside class="userlist" data-userlist-drawer-target="drawer">
      <%= yield :userlist %>
    </aside>
  <% end %>
</div>
```

Wait, the yield :userlist is the partial content. We need the partial to NOT include the `<aside>` wrapper since it's in the layout. Let me reconsider...

### Revised Step 1: Update `channels/_user_list.html.erb`

The partial should just be the inner content:
```erb
<div id="channel_<%= channel.id %>_user_list" class="user-list-inner">
  <div class="drawer-header">
    <span class="title"><%= channel.channel_users.size %> users</span>
    <button class="close" data-action="userlist-drawer#close" aria-label="Close">&times;</button>
  </div>
  <div class="content">
    <%= render "channels/user_list_content", channel: channel %>
  </div>
</div>
```

### Revised Step 3: Layout

```erb
<% if content_for?(:userlist) %>
  <div class="userlist-backdrop" data-userlist-drawer-target="backdrop" data-action="click->userlist-drawer#backdropClick"></div>
  <aside class="userlist" data-userlist-drawer-target="drawer">
    <%= yield :userlist %>
  </aside>
<% end %>
```

### Step 4: Move Controller to Layout

The `data-controller="userlist-drawer"` moves from the header to the app-layout div. The toggle button in the header uses the action `userlist-drawer#open` which bubbles up to find the controller.

### Step 5: Update CSS

**`app-layout.css`**:
```css
& > .userlist {
  grid-row: 2;
  overflow-y: auto;
  background: var(--color-surface);
  border-left: 1px solid var(--color-border);
}

@media (max-width: 1023px) {
  & > .userlist {
    position: fixed;
    top: var(--header-height);
    right: 0;
    bottom: 0;
    width: 240px;
    transform: translateX(100%);
    transition: transform 0.2s ease;
    z-index: 200;
  }

  & > .userlist.-open {
    transform: translateX(0);
  }
}
```

**New or updated CSS for drawer header**:
```css
.user-list-inner .drawer-header {
  display: none; /* Hidden on desktop */
}

@media (max-width: 1023px) {
  .user-list-inner .drawer-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 12px 16px;
    border-bottom: 1px solid var(--color-border);
  }
}
```

### Step 6: Update Turbo Broadcast Target

The ChannelUser broadcast targets `channel_#{id}_user_list`. This ID is on the inner div, not the aside. The broadcast replaces this div, which is inside the aside. This should work fine.

Actually, check current broadcast:
```ruby
broadcast_replace_to(
  [ channel, :users ],
  target: "channel_#{channel.id}_user_list",
  partial: "channels/user_list",
  locals: { channel: channel }
)
```

The partial `channels/user_list` renders the div with that ID. So broadcast replaces the entire inner content. This will work as long as the ID is on the inner div that gets replaced.

## Tests

### System Tests

**Desktop: user list visible without interaction**
- Given: logged in user viewing channel on desktop viewport (≥1024px)
- Then: user list is visible in right sidebar
- And: no toggle button visible (or button hidden)

**Mobile: user list hidden by default**
- Given: logged in user viewing channel on mobile viewport (<1024px)
- Then: user list is NOT visible
- And: toggle button is visible in header

**Mobile: toggle button opens user list**
- Given: mobile viewport with user list hidden
- When: clicking toggle button
- Then: user list slides in from right
- And: backdrop appears

**Mobile: backdrop click closes user list**
- Given: mobile viewport with user list open
- When: clicking backdrop
- Then: user list slides out
- And: backdrop disappears

**Mobile: close button closes user list**
- Given: mobile viewport with user list open
- When: clicking close button in drawer header
- Then: user list closes

**Mobile: Escape key closes user list**
- Given: mobile viewport with user list open
- When: pressing Escape key
- Then: user list closes

**Live update works on desktop**
- Given: desktop viewport viewing channel
- When: user joins channel (ChannelUser created)
- Then: user list updates to show new user

**Live update works on mobile (drawer open)**
- Given: mobile viewport with user list drawer open
- When: user joins channel (ChannelUser created)
- Then: user list updates to show new user without closing drawer

**Live update works on mobile (drawer closed)**
- Given: mobile viewport with user list drawer closed
- When: user joins channel (ChannelUser created)
- And: then opening the drawer
- Then: user list shows the new user

**User list not duplicated in HTML**
- Given: viewing channel page source
- Then: only ONE element with user list content exists
- And: NOT two separate user list containers

## Implementation Notes

- The key insight: same DOM element, CSS changes its presentation based on viewport
- Turbo Stream target remains the same ID, updates work for both modes
- The Stimulus controller might need minor adjustments for the new DOM structure
- Test that the backdrop z-index is correct (below drawer, above main content)
- The drawer header (with close button) should only be visible on mobile
- Consider: should the user count in the toggle button update live? Currently it's in the header partial which doesn't get Turbo updates. May need a separate Turbo Frame or accept it updates on page load.

## Dependencies

- Feature 39 (Unify DM and Channel views) should be done first, as it may touch the same view files
