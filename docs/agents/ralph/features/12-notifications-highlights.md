# Highlights and Notifications

## Description

Users are notified when:
- Someone mentions their nickname (highlight)
- Someone sends them a private message (DM)

Notifications appear as badges and trigger browser push notifications.

## Behavior

### What Creates a Notification

**Highlight:**
- Message contains user's nickname (case-insensitive)
- In a channel (not PM - PMs are already notifications)
- Not from the user themselves

**DM:**
- Private message to the user
- Not from the user themselves

### Notification Record

When these events occur, create a Notification:
```ruby
Notification.create!(
  message: message,
  reason: "highlight" | "dm",
  read_at: nil
)
```

### Notification Badge

In the header/nav, show a notification bell with count:
- Count of unread notifications (where read_at is nil)
- Clicking opens notification dropdown/page

### Notification List

Show recent notifications:
- Who sent it
- Preview of message
- Which channel (or "Direct Message")
- Timestamp
- Click to go to that message

### Marking as Read

- Clicking a notification marks it as read
- "Mark all as read" button
- Viewing the channel/PM could mark related notifications as read

### Browser Push Notifications

When a notification is created:
- If user has granted permission, send browser notification
- Notification shows: sender, preview, channel
- Clicking notification focuses the app and navigates to message

### Web Push Setup

Using the Web Push API:
1. Request permission on first visit (or via settings)
2. Register service worker
3. Subscribe to push
4. Store subscription endpoint in database
5. When notification created, send push via subscription

For MVP, can use simple Notification API (no service worker) which works when tab is open.

## Models

### Notification

See `docs/agents/data-model.md`.

```ruby
class Notification < ApplicationRecord
  belongs_to :message
  
  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc).limit(50) }
  
  def read?
    read_at.present?
  end
  
  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end
end
```

### User Push Subscription (optional for MVP)

```ruby
# If implementing full web push
class PushSubscription < ApplicationRecord
  belongs_to :user
  
  # endpoint, p256dh_key, auth_key from browser
end
```

## Creating Notifications

In IRC process (from messages-receive feature):

```ruby
def handle_privmsg(event)
  Tenant.switch(@server.user) do
    # ... create message ...
    
    # Check for highlight (channel message containing our nick)
    if channel && content.downcase.include?(@server.nickname.downcase)
      notification = Notification.create!(message: message, reason: "highlight")
      send_browser_notification(notification)
    end
    
    # DM creates notification (already in messages-receive)
    if !channel && event.target.downcase == @server.nickname.downcase
      notification = Notification.create!(message: message, reason: "dm")
      send_browser_notification(notification)
    end
  end
end

def send_browser_notification(notification)
  # Broadcast to user's notification stream
  ActionCable.server.broadcast(
    "user_#{@server.user.id}_notifications",
    {
      type: "notification",
      id: notification.id,
      reason: notification.reason,
      sender: notification.message.sender,
      preview: notification.message.content.truncate(100),
      channel: notification.message.channel&.name
    }
  )
end
```

## Controller

```ruby
# app/controllers/notifications_controller.rb
class NotificationsController < ApplicationController
  def index
    @notifications = Notification.unread.recent
  end
  
  def update
    @notification = Notification.find(params[:id])
    @notification.mark_as_read!
    
    redirect_to notification_target_path(@notification)
  end
  
  def mark_all_read
    Notification.unread.update_all(read_at: Time.current)
    redirect_back fallback_location: root_path
  end
  
  private
  
  def notification_target_path(notification)
    if notification.message.channel
      channel_path(notification.message.channel, anchor: "message_#{notification.message.id}")
    else
      # PM view - depends on how we handle PMs
      server_path(notification.message.server, pm: notification.message.target)
    end
  end
end
```

## Routes

```ruby
resources :notifications, only: [:index, :update] do
  collection do
    post :mark_all_read
  end
end
```

Wait - we said no custom actions. Let's fix:

```ruby
resources :notifications, only: [:index, :update]
resources :notification_reads, only: [:create]  # mark all read
```

Or just use update on individual notifications and skip "mark all".

## JavaScript: Browser Notifications

```javascript
// app/javascript/controllers/notifications_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.requestPermission()
    this.subscribeToChannel()
  }
  
  requestPermission() {
    if ("Notification" in window && Notification.permission === "default") {
      Notification.requestPermission()
    }
  }
  
  subscribeToChannel() {
    // Subscribe to Action Cable channel for notifications
    this.subscription = this.application
      .consumer
      .subscriptions
      .create("NotificationsChannel", {
        received: (data) => this.handleNotification(data)
      })
  }
  
  handleNotification(data) {
    // Update badge count
    this.updateBadge(data)
    
    // Show browser notification
    if (Notification.permission === "granted") {
      const title = data.reason === "dm" ? `DM from ${data.sender}` : `${data.sender} in ${data.channel}`
      new Notification(title, {
        body: data.preview,
        tag: `notification-${data.id}`,
        requireInteraction: true
      })
    }
  }
  
  updateBadge(data) {
    // Increment badge count in header
    const badge = document.querySelector(".notification-badge")
    if (badge) {
      const count = parseInt(badge.textContent || "0") + 1
      badge.textContent = count
      badge.classList.remove("hidden")
    }
  }
}
```

## Tests

### Model: Notification

**belongs_to message**
**scope unread returns notifications without read_at**
**scope recent orders by created_at desc, limits 50**
**read? returns true when read_at present**
**mark_as_read! sets read_at**

### Controller: NotificationsController

**GET /notifications**
- Returns 200
- Lists unread notifications

**PATCH /notifications/:id**
- Marks notification as read
- Redirects to message location

### Integration: Highlight Notification

**Message containing nickname creates notification**
- User nickname is "joe"
- Message arrives: "hey joe check this out"
- Notification created with reason "highlight"

**Notification appears in header badge**
- Notification created
- Badge count increments

**Clicking notification goes to message**
- Have notification
- Click it
- Navigated to channel with message visible

### Integration: DM Notification

**Private message creates notification**
- PM received
- Notification created with reason "dm"

### Unit: Highlight Detection

**Detects nickname in message (case insensitive)**
- Nickname: "Joe"
- Message: "JOE: hello" → highlight
- Message: "hey joe" → highlight
- Message: "joey is here" → NOT highlight (partial match - decide on behavior)

For partial match: probably should NOT highlight "joey" when nick is "joe". Use word boundary:
```ruby
content.downcase.match?(/\b#{Regexp.escape(nickname.downcase)}\b/)
```

## Implementation Notes

- Browser Notification API requires HTTPS in production (localhost works for dev)
- Consider notification preferences later (mute channels, quiet hours)
- Badge should update in real-time via Turbo Stream or Action Cable
- For MVP, skip service worker - just use Notification API when tab is open
- Word boundary matching for highlights to avoid false positives

## Dependencies

- Requires `messages-receive.md` (messages being created)
- Requires `channels.md` (for navigation to channel)
