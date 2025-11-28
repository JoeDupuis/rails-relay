# Private Messages

## Description

Private messages (DMs) appear in the sidebar alongside channels, grouped under their server. Users can view PM conversations and send messages to other users.

## Behavior

### Sidebar Structure

```
▾ irc.libera.chat (●)
    DMs
      alice (2)
      bob
    Channels
      # ruby (3)
      # rails
```

- DMs section appears above Channels section
- Each DM shows the other person's nick
- Unread count badge if has unread messages
- Clicking opens the PM conversation view

### PM Conversation View

Same layout as channel view:
- Header shows nick instead of channel name
- No topic (or could show user's realname/status if we have it)
- No user list sidebar
- Message history
- Input to send messages

### Starting a PM

Ways to start a PM:
1. Receive a PM from someone (appears in sidebar automatically)
2. Use `/msg nick message` command in any channel
3. Click on a nick in the user list (future feature)

When a PM is received from a new person:
- Create a Conversation record (or derive from messages)
- Show in sidebar under DMs

### Data Model Options

Option A: Derive from Messages
- No new model
- Query messages where `channel_id IS NULL` and group by `target`
- Sidebar shows distinct targets from recent PMs

Option B: Explicit Conversation Model
```ruby
class Conversation < ApplicationRecord
  belongs_to :server
  # target_nick - the other person
  # last_message_at - for sorting
  # last_read_message_id - for unread tracking
end
```

**Recommendation:** Option B - explicit model makes unread tracking and ordering cleaner.

### Conversation Model

```ruby
# app/models/conversation.rb
class Conversation < ApplicationRecord
  belongs_to :server
  
  validates :target_nick, presence: true
  validates :target_nick, uniqueness: { scope: :server_id }
  
  def messages
    Message.where(server: server, channel_id: nil)
           .where("target = ? OR sender = ?", target_nick, target_nick)
           .order(:created_at)
  end
  
  def unread_count
    return 0 unless last_read_message_id
    messages.where("id > ?", last_read_message_id).count
  end
  
  def unread?
    unread_count > 0
  end
  
  def mark_as_read!
    update!(last_read_message_id: messages.maximum(:id))
  end
end
```

| Column | Type | Notes |
|--------|------|-------|
| id | integer | primary key |
| server_id | integer | references Server |
| target_nick | string | the other person's nick |
| last_read_message_id | integer | for unread tracking |
| last_message_at | datetime | for sorting in sidebar |
| created_at | datetime | |
| updated_at | datetime | |

### Creating Conversations

When a PM is received (in IRC process):
```ruby
def handle_privmsg(event)
  # ... existing channel message handling ...
  
  if !channel && event.target.downcase == @server.nickname.downcase
    # This is a PM to us
    conversation = Conversation.find_or_create_by!(
      server: @server,
      target_nick: event.nick
    )
    conversation.touch(:last_message_at)
    
    message = Message.create!(
      server: @server,
      channel: nil,
      target: event.nick,
      sender: event.nick,
      content: event.message,
      message_type: "privmsg"
    )
    
    Notification.create!(message: message, reason: "dm")
  end
end
```

When sending a PM:
```ruby
def send_pm(nick, content)
  conversation = Conversation.find_or_create_by!(
    server: @server,
    target_nick: nick
  )
  conversation.touch(:last_message_at)
  
  IrcCommandSender.new(@server).privmsg(nick, content)
  
  Message.create!(
    server: @server,
    channel: nil,
    target: nick,
    sender: @server.nickname,
    content: content,
    message_type: "privmsg"
  )
end
```

### Sidebar Update

```erb
<%# app/views/shared/_sidebar.html.erb %>
<% current_user_servers.each do |server| %>
  <div class="servergroup">
    <div class="servername">
      <%= link_to server.address, server_path(server) %>
    </div>
    
    <% if server.conversations.any? %>
      <div class="section-label">DMs</div>
      <ul class="dm-list">
        <% server.conversations.order(last_message_at: :desc).each do |convo| %>
          <li class="dm-item <%= '-unread' if convo.unread? %> <%= '-active' if current_conversation == convo %>">
            <%= link_to conversation_path(convo), class: "link" do %>
              <%= convo.target_nick %>
              <% if convo.unread_count > 0 %>
                <span class="badge"><%= convo.unread_count %></span>
              <% end %>
            <% end %>
          </li>
        <% end %>
      </ul>
    <% end %>
    
    <div class="section-label">Channels</div>
    <ul class="channel-list">
      <% server.channels.each do |channel| %>
        <%# ... existing channel items ... %>
      <% end %>
    </ul>
  </div>
<% end %>
```

### Routes

```ruby
resources :conversations, only: [:show] do
  resources :messages, only: [:create]
end
```

### Controller

```ruby
# app/controllers/conversations_controller.rb
class ConversationsController < ApplicationController
  def show
    @conversation = Conversation.find(params[:id])
    @conversation.mark_as_read!
    @server = @conversation.server
    @messages = @conversation.messages.order(:created_at).last(50)
  end
end
```

### View

```erb
<%# app/views/conversations/show.html.erb %>
<div class="channel-view" data-controller="channel">
  <header class="header">
    <span class="name"><%= @conversation.target_nick %></span>
    <span class="subtitle">Direct Message</span>
  </header>
  
  <div class="messages" data-controller="message-list">
    <div id="messages">
      <%= render partial: "messages/message", collection: @messages, as: :message %>
    </div>
  </div>
  
  <div class="input">
    <%= form_with url: conversation_messages_path(@conversation), class: "message-input" do |f| %>
      <%= f.text_field :content, placeholder: "Message #{@conversation.target_nick}", class: "field" %>
      <%= f.submit "Send", class: "submit" %>
    <% end %>
  </div>
</div>
```

### Messages Controller (for conversations)

```ruby
# Nested under conversations
# POST /conversations/:conversation_id/messages
class Conversation::MessagesController < ApplicationController
  def create
    @conversation = Conversation.find(params[:conversation_id])
    @server = @conversation.server
    
    content = params[:content]
    
    IrcCommandSender.new(@server).privmsg(@conversation.target_nick, content)
    
    @message = Message.create!(
      server: @server,
      channel: nil,
      target: @conversation.target_nick,
      sender: @server.nickname,
      content: content,
      message_type: "privmsg"
    )
    
    @conversation.touch(:last_message_at)
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @conversation }
    end
  end
end
```

## CSS

```css
.dm-item {
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

.section-label {
  padding: 8px 12px 4px;
  font-size: var(--font-xs);
  font-weight: 600;
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
```

## Tests

### Model: Conversation

**validates target_nick presence**
**validates uniqueness of target_nick per server**
**messages returns messages for this conversation**
**unread_count returns count after last_read_message_id**
**mark_as_read! updates last_read_message_id**

### Controller: ConversationsController#show

**GET /conversations/:id**
- Returns 200
- Shows messages
- Marks as read

**User can only view their own conversations**
- Conversation belongs to User A
- Sign in as User B
- GET /conversations/:id
- Returns 404

### Controller: Conversation::MessagesController#create

**POST /conversations/:id/messages**
- Creates message
- Sends IRC command
- Updates last_message_at
- Returns Turbo Stream

### Integration: PM Flow

**Receiving a PM creates conversation**
- No existing conversation with alice
- IRC process receives PM from alice
- Conversation created
- Appears in sidebar

**Sending a PM to new person**
- Use /msg bob hello in a channel
- Conversation with bob created
- Message sent

**Viewing PM conversation**
- Have conversation with alice
- Click alice in sidebar
- See message history
- Can send reply

### Integration: Sidebar Display

**DMs appear above channels**
- User has DMs and channels
- Sidebar shows DMs section first
- Then channels section

**DMs sorted by recent activity**
- Have conversations with alice (older) and bob (newer)
- Bob appears first in list

**Unread badge on DM**
- Conversation has unread messages
- Badge shows count

## Implementation Notes

- Reuse channel-view styling for conversation view
- Conversation messages use same partial as channel messages
- Real-time updates via Turbo Streams work the same way
- Consider: what if nick changes? Messages reference old nick but conversation has... which nick? (Edge case, can defer)

## Dependencies

- Requires `messages-receive.md` (PM handling exists)
- Requires `messages-send.md` (sending PMs)
- Requires `ui-layout.md` (sidebar structure)
