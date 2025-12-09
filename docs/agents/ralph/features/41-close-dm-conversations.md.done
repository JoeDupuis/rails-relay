# Close DM Conversations

## Description

Currently, once a DM conversation is created, it stays in the sidebar forever. Users should be able to "close" a DM to remove it from the sidebar. The conversation should automatically reopen when a new message arrives from that user.

## Behavior

### Closing a DM

Add a close button (X) to each DM item in the sidebar. Clicking it:
1. Hides the DM from the sidebar immediately
2. Sets `closed_at` timestamp on the Conversation record
3. If currently viewing that DM, redirects to server page

### Closed State

A "closed" conversation:
- Does NOT appear in the sidebar
- Is NOT deleted (messages preserved)
- Can be reopened

### Auto-Reopen on New Message

When a new message arrives for a closed conversation:
1. Clear the `closed_at` field
2. Broadcast sidebar update to show the DM again
3. DM appears in sidebar with unread indicator

### Manually Reopening

Users can reopen a closed DM by:
- Clicking a username in a channel (existing DM initiation flow)
- This finds the existing conversation, clears `closed_at`, and shows it

### Sidebar Query Change

The sidebar currently shows all conversations:
```ruby
server.conversations.order(last_message_at: :desc)
```

Change to only show open conversations:
```ruby
server.conversations.open.order(last_message_at: :desc)
```

## Models

### Conversation

Add field:
- `closed_at` (datetime, nullable) - timestamp when closed, null means open

Add scope:
```ruby
scope :open, -> { where(closed_at: nil) }
scope :closed, -> { where.not(closed_at: nil) }
```

Add methods:
```ruby
def closed?
  closed_at.present?
end

def close!
  update!(closed_at: Time.current)
end

def reopen!
  return unless closed?
  update!(closed_at: nil)
end
```

Modify existing logic:
- When a new message arrives for a closed conversation, call `reopen!` and broadcast sidebar add

### Migration

```ruby
class AddClosedAtToConversations < ActiveRecord::Migration[8.0]
  def change
    add_column :conversations, :closed_at, :datetime
  end
end
```

## Controllers

### ConversationsController

Add `close` action:
```ruby
def close
  @conversation = Conversation.find(params[:id])
  @conversation.close!
  @conversation.broadcast_sidebar_remove

  redirect_to server_path(@conversation.server), notice: "Conversation closed"
end
```

Add route:
```ruby
resources :conversations, only: [:show] do
  member do
    post :close
  end
end
```

### Modify DM Initiation

When initiating a DM (clicking username), if conversation exists but is closed, reopen it:
```ruby
# In conversations#create or wherever DM initiation happens
conversation = server.conversations.find_or_initialize_by(target_nick: params[:target_nick])
conversation.reopen! if conversation.closed?
conversation.save! if conversation.new_record?
```

## Views

### `shared/_conversation_sidebar_item.html.erb`

Add close button:
```erb
<li id="conversation_<%= conversation.id %>_sidebar" class="dm-item ...">
  <span class="presence-indicator ..."></span>
  <%= link_to conversation_path(conversation), class: "link" do %>
    <%= conversation.target_nick %>
    <% if conversation.unread_count > 0 %>
      <span class="badge"><%= conversation.unread_count %></span>
    <% end %>
  <% end %>
  <%= button_to close_conversation_path(conversation), method: :post, class: "close-btn", data: { turbo_confirm: false } do %>
    <span aria-label="Close conversation">&times;</span>
  <% end %>
</li>
```

### CSS

Style the close button to appear on hover:
```css
.dm-item .close-btn {
  opacity: 0;
  /* position, size, etc. */
}

.dm-item:hover .close-btn {
  opacity: 1;
}
```

## Broadcasts

### Conversation Model

Add broadcast for removal:
```ruby
def broadcast_sidebar_remove
  return unless server.user_id

  broadcast_remove_to(
    "sidebar_#{server.user_id}",
    target: "conversation_#{id}_sidebar"
  )
end
```

Modify the message handling to reopen closed conversations. This likely happens in `IrcEventHandler` or Message model callbacks. When creating a message for a DM:
```ruby
conversation = Conversation.find_or_create_for_dm(server, target_nick)
if conversation.closed?
  conversation.reopen!
  conversation.broadcast_sidebar_add
end
```

## Tests

### Model Tests

**Conversation#closed? returns false for new conversation**
- Given: new conversation with closed_at nil
- When: calling closed?
- Then: returns false

**Conversation#closed? returns true when closed_at set**
- Given: conversation with closed_at set
- When: calling closed?
- Then: returns true

**Conversation#close! sets closed_at**
- Given: open conversation
- When: calling close!
- Then: closed_at is set to current time

**Conversation#reopen! clears closed_at**
- Given: closed conversation
- When: calling reopen!
- Then: closed_at is nil

**Conversation.open scope excludes closed conversations**
- Given: 2 open conversations and 1 closed
- When: calling Conversation.open
- Then: returns only the 2 open conversations

**Conversation.closed scope returns only closed conversations**
- Given: 2 open conversations and 1 closed
- When: calling Conversation.closed
- Then: returns only the 1 closed conversation

### Controller Tests

**POST /conversations/:id/close closes conversation**
- Given: logged in user with open conversation
- When: POST to close_conversation_path
- Then: conversation is closed
- And: redirects to server page
- And: broadcasts sidebar remove

**POST /conversations/:id/close for other user's conversation**
- Given: logged in user
- And: conversation belonging to different user
- When: POST to close_conversation_path
- Then: returns 404 or redirects with error

### Integration Tests

**Closing DM broadcasts sidebar remove**
- Given: open conversation
- When: close! is called
- Then: broadcasts remove to sidebar stream

**Reopening DM broadcasts sidebar add**
- Given: closed conversation
- When: reopen! is called
- Then: broadcasts append to sidebar stream

**New message reopens closed conversation**
- Given: closed conversation with target_nick "alice"
- When: new message arrives from "alice"
- Then: conversation is reopened
- And: broadcasts sidebar add
- And: conversation appears in Conversation.open

### System Tests

**Close button appears on hover**
- Given: logged in user viewing sidebar with DM
- When: hovering over DM item
- Then: close button becomes visible

**Clicking close removes DM from sidebar**
- Given: logged in user viewing sidebar with DM to "alice"
- When: clicking close button on that DM
- Then: DM disappears from sidebar
- And: redirected to server page

**Closed DM reappears on new message**
- Given: logged in user with closed DM to "alice"
- When: new message arrives from "alice" (simulated)
- Then: DM appears in sidebar
- And: shows unread indicator

**Clicking username reopens closed DM**
- Given: logged in user with closed DM to "alice"
- And: "alice" visible in channel user list
- When: clicking "alice" in user list
- Then: existing conversation is reopened
- And: DM appears in sidebar
- And: redirected to conversation page

## Implementation Notes

- The close button should be styled subtly (appears on hover) to not clutter the sidebar
- When closing the currently viewed DM, redirect to avoid showing a blank/stale view
- The auto-reopen on new message logic is critical - find where DM messages are created and add the reopen check
- Consider: should closing a DM also mark it as read? Probably yes, to avoid confusion
- The `closed_at` timestamp could be useful for "recently closed" UI in the future

## Dependencies

- Feature 40 (DM user online status) - for presence indicator in sidebar item (or can be done in parallel)
