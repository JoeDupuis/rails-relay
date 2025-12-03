# Mobile User List Drawer

## Description

On tablet/mobile viewports (< 1024px), the user list is hidden with `display: none`. Users have no way to see who is in a channel on smaller screens.

Add a slide-in drawer from the right side that shows the user list when a toggle button is tapped.

## Behavior

### User List Toggle Button
- Only visible on viewports < 1024px (where userlist is normally hidden)
- Positioned in the channel header, right side
- Shows user count icon (e.g., users icon + number like "👥 12")
- Tapping opens the user list drawer

### User List Drawer
- Slides in from the right edge of the screen
- Width: 240px on tablet, full width on phone (< 768px)
- Contains same content as desktop user list:
  - User count header
  - Operators section
  - Voiced section
  - Regular users section
- Has a close button (X) in top right
- Clicking outside drawer closes it
- Overlay/backdrop behind drawer (semi-transparent)

### Accessibility
- Focus trapped inside drawer when open
- Escape key closes drawer
- Close button is focusable and activates on Enter/Space

### Animation
- Smooth slide-in animation (200ms ease-out)
- Backdrop fades in

## Implementation

### 1. Create Stimulus Controller

Create `app/javascript/controllers/userlist_drawer_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["drawer", "backdrop"]

  open() {
    this.drawerTarget.classList.add("-open")
    this.backdropTarget.classList.add("-visible")
    document.body.style.overflow = "hidden"
  }

  close() {
    this.drawerTarget.classList.remove("-open")
    this.backdropTarget.classList.remove("-visible")
    document.body.style.overflow = ""
  }

  backdropClick(event) {
    if (event.target === this.backdropTarget) {
      this.close()
    }
  }

  keydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
```

### 2. Update Channel Header

In `app/views/channels/_header.html.erb`, add toggle button visible only on mobile:

```erb
<header class="channel-header" data-controller="userlist-drawer">
  <div class="channel-info">
    <!-- existing header content -->
  </div>

  <button class="userlist-toggle"
          data-action="userlist-drawer#open"
          aria-label="Show user list">
    <span class="icon">👥</span>
    <span class="count"><%= @channel.channel_users.count %></span>
  </button>

  <div class="userlist-backdrop"
       data-userlist-drawer-target="backdrop"
       data-action="click->userlist-drawer#backdropClick"></div>

  <aside class="userlist-drawer"
         data-userlist-drawer-target="drawer"
         data-action="keydown->userlist-drawer#keydown">
    <header class="drawer-header">
      <h3>Users (<%= @channel.channel_users.count %>)</h3>
      <button class="close-btn"
              data-action="userlist-drawer#close"
              aria-label="Close user list">&times;</button>
    </header>
    <div class="drawer-content">
      <%= render "channels/user_list_content", channel: @channel %>
    </div>
  </aside>
</header>
```

### 3. Extract User List Content Partial

Create `app/views/channels/_user_list_content.html.erb` with the inner content of user list (sections for ops, voiced, regular).

Update `app/views/channels/_user_list.html.erb` to use the partial:

```erb
<div class="user-list" id="channel_<%= channel.id %>_user_list">
  <%= render "channels/user_list_content", channel: channel %>
</div>
```

### 4. Add CSS

In `app/assets/stylesheets/components/userlist-drawer.css`:

```css
.userlist-toggle {
  display: none;
  align-items: center;
  gap: 4px;
  padding: 6px 10px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  background: var(--color-surface);
  cursor: pointer;
}

.userlist-backdrop {
  display: none;
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.3);
  z-index: 199;
  opacity: 0;
  transition: opacity 0.2s ease;
}

.userlist-backdrop.-visible {
  opacity: 1;
}

.userlist-drawer {
  display: none;
  position: fixed;
  top: var(--header-height);
  right: 0;
  bottom: 0;
  width: 240px;
  background: var(--color-surface);
  border-left: 1px solid var(--color-border);
  transform: translateX(100%);
  transition: transform 0.2s ease;
  z-index: 200;
  overflow-y: auto;
}

.userlist-drawer.-open {
  transform: translateX(0);
}

.userlist-drawer .drawer-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  border-bottom: 1px solid var(--color-border);
}

.userlist-drawer .close-btn {
  font-size: 24px;
  background: none;
  border: none;
  cursor: pointer;
  padding: 0;
  line-height: 1;
}

.userlist-drawer .drawer-content {
  padding: 12px;
}

@media (max-width: 1023px) {
  .userlist-toggle {
    display: flex;
  }

  .userlist-backdrop {
    display: block;
    pointer-events: none;
  }

  .userlist-backdrop.-visible {
    pointer-events: auto;
  }

  .userlist-drawer {
    display: block;
  }
}

@media (max-width: 767px) {
  .userlist-drawer {
    width: 100%;
  }
}
```

### 5. Import CSS

Add import to `app/assets/stylesheets/application.css`:

```css
@import "components/userlist-drawer.css";
```

## Tests

### System Tests

**Toggle button visible on mobile**
- Given: Viewport width is 768px
- When: User views channel page
- Then: User list toggle button is visible in header
- And: Desktop user list sidebar is hidden

**Toggle button hidden on desktop**
- Given: Viewport width is 1200px
- When: User views channel page
- Then: User list toggle button is NOT visible
- And: Desktop user list sidebar IS visible

**Open drawer**
- Given: Mobile viewport, viewing channel
- When: User taps toggle button
- Then: Drawer slides in from right
- And: Backdrop overlay appears

**Close drawer with X button**
- Given: Drawer is open
- When: User taps close button
- Then: Drawer slides out
- And: Backdrop disappears

**Close drawer by clicking backdrop**
- Given: Drawer is open
- When: User clicks on backdrop (outside drawer)
- Then: Drawer closes

**Close drawer with Escape key**
- Given: Drawer is open
- When: User presses Escape
- Then: Drawer closes

**Drawer shows user list content**
- Given: Channel has operators, voiced, and regular users
- When: User opens drawer
- Then: All user sections are visible with correct users

### Controller Tests (JavaScript)

**open() adds classes**
- Adds `-open` to drawer
- Adds `-visible` to backdrop

**close() removes classes**
- Removes `-open` from drawer
- Removes `-visible` from backdrop

## Dependencies

None - this is a new mobile-specific feature.
