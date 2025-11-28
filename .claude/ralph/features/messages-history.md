# Message History

## Description

Users can scroll back through message history in channels. Messages are loaded in pages, with older messages loaded on demand.

## Behavior

### Initial Load

When viewing a channel:
- Load most recent N messages (e.g., 50)
- Display newest at bottom
- Scroll position starts at bottom

### Loading Older Messages

- Scroll to top of message list
- "Load more" link/button appears, OR
- Automatically load when scrolling near top (infinite scroll)
- Load next N older messages
- Prepend to message list
- Maintain scroll position (don't jump)

### Message Display

Each message shows:
- Sender nickname
- Timestamp (time, or date+time if different day)
- Message content
- Visual distinction for message types (action, notice, join/part, etc.)

### Date Separators

When messages span multiple days:
- Insert date separator between days
- Format: "January 15, 2025" or "Today", "Yesterday"

### Scroll Behavior

- New messages: auto-scroll to bottom IF already at bottom
- If user has scrolled up: don't auto-scroll, show "new messages" indicator
- Clicking indicator scrolls to bottom

## Controller

```ruby
# app/controllers/channels_controller.rb
class ChannelsController < ApplicationController
  def show
    @channel = Channel.find(params[:id])
    @messages = @channel.messages
                        .order(created_at: :desc)
                        .limit(50)
                        .reverse  # Show oldest-to-newest in view
  end
end

# For loading more (could be separate controller)
# app/controllers/channel_messages_controller.rb
class ChannelMessagesController < ApplicationController
  def index
    @channel = Channel.find(params[:channel_id])
    @messages = @channel.messages
                        .where("id < ?", params[:before])
                        .order(created_at: :desc)
                        .limit(50)
                        .reverse
    
    respond_to do |format|
      format.turbo_stream
      format.html { render partial: "messages/messages", locals: { messages: @messages } }
    end
  end
end
```

## Routes

```ruby
resources :channels, only: [:show] do
  resources :messages, only: [:index], controller: "channel_messages"
end
```

`GET /channels/:channel_id/messages?before=123` - Load messages older than ID 123

## View Structure

```erb
<%# app/views/channels/show.html.erb %>
<div class="channel-view">
  <header class="channel-header">
    <h1><%= @channel.name %></h1>
    <p class="topic"><%= @channel.topic %></p>
  </header>
  
  <div class="message-list" 
       data-controller="message-list"
       data-message-list-channel-id-value="<%= @channel.id %>">
    
    <div class="loadmore" data-message-list-target="loadMore">
      <%= link_to "Load older messages", 
          channel_messages_path(@channel, before: @messages.first&.id),
          data: { turbo_frame: "older_messages" } %>
    </div>
    
    <turbo-frame id="older_messages"></turbo-frame>
    
    <div id="messages" data-message-list-target="messages">
      <%= render @messages %>
    </div>
  </div>
  
  <%= render "messages/form", channel: @channel %>
</div>
```

## Stimulus Controller

```javascript
// app/javascript/controllers/message_list_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "loadMore", "newIndicator"]
  static values = { channelId: Number }
  
  connect() {
    this.scrollToBottom()
    this.observeScroll()
  }
  
  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }
  
  observeScroll() {
    // Track if user is at bottom
    this.messagesTarget.addEventListener("scroll", () => {
      this.atBottom = this.isAtBottom()
    })
  }
  
  isAtBottom() {
    const el = this.messagesTarget
    return el.scrollHeight - el.scrollTop - el.clientHeight < 50
  }
  
  // Called when new message arrives via Turbo Stream
  messageAdded() {
    if (this.atBottom) {
      this.scrollToBottom()
    } else {
      this.showNewIndicator()
    }
  }
  
  showNewIndicator() {
    this.newIndicatorTarget.classList.remove("hidden")
  }
  
  scrollToNew() {
    this.scrollToBottom()
    this.newIndicatorTarget.classList.add("hidden")
  }
}
```

## Tests

### Controller: ChannelsController#show

**GET /channels/:id**
- Returns 200
- Loads recent messages (limit 50)
- Orders oldest to newest for display

**GET /channels/:id with many messages**
- Only returns 50 messages
- Returns most recent 50

### Controller: ChannelMessagesController#index

**GET /channels/:id/messages?before=100**
- Returns messages with id < 100
- Limits to 50
- Orders correctly

**GET with no more messages**
- Returns empty collection
- No error

### Integration: Message History

**User views channel with history**
- Channel has 100 messages
- Visit channel
- See 50 most recent
- Scroll to top
- Click load more
- See older messages prepended

**New message while scrolled up**
- View channel, scroll up
- New message arrives
- Message added to bottom
- "New messages" indicator shown
- Click indicator, scroll to bottom

### Model: Message Scopes

**Channel#messages ordered by created_at**
**Messages can be filtered by id (before/after)**

## Implementation Notes

- Use Turbo Frames for "load more" to avoid full page reload
- Consider Intersection Observer for automatic infinite scroll
- Date separators can be computed in view helper or added as pseudo-messages
- For very long history, consider limiting how far back they can scroll (or paginate differently)
- scroll-behavior: smooth for nice UX

## Dependencies

- Requires `channels.md` (Channel model and view)
- Requires `messages-receive.md` (Messages exist to display)
