# DM Initiation

## Description

There's no user-friendly way to start a DM conversation with someone. The `/msg nick message` command exists but:
1. It doesn't create a Conversation record, so it doesn't appear in the sidebar
2. Users don't know about the command
3. There's no way to click on a username to start a DM

## Behavior

### Click Username to Start DM
- Clicking a username in the user list opens/creates a DM conversation with that user
- Clicking a username in a message opens/creates a DM conversation with that user
- If conversation already exists, navigates to it
- If conversation doesn't exist, creates it and navigates to it

### /msg Command Creates Conversation
- When using `/msg nick message` in a channel
- Creates or finds Conversation record for that nick
- Message is saved with conversation context
- Conversation appears in sidebar

### /msg in Conversation View
- When already in a DM with "bob", typing `/msg alice hello` should:
  - Send to alice (not bob)
  - Create/find Conversation for alice
  - Navigate to alice's conversation

## Implementation

### 1. Fix /msg to Create Conversation

In `app/controllers/messages_controller.rb`, update `send_pm`:

```ruby
def send_pm(nick, content)
  return unless send_irc_command("privmsg", target: nick, message: content)

  conversation = Conversation.find_or_create_by!(server: @server, target_nick: nick)
  conversation.touch(:last_message_at)

  @message = Message.create!(
    server: @server,
    channel: nil,
    target: nick,
    sender: @server.nickname,
    content: content,
    message_type: "privmsg"
  )

  # After creating conversation, redirect to it (for HTML requests)
  @created_conversation = conversation
end
```

Update the response handling to redirect to conversation:

```ruby
def create
  # ... existing case/when logic ...

  return if performed?

  respond_to do |format|
    format.turbo_stream do
      if @created_conversation
        # For /msg commands, replace message input and navigate
        render turbo_stream: [
          turbo_stream.replace("message_input", partial: "channels/input", locals: { channel: @channel }),
          turbo_stream.action(:visit, conversation_path(@created_conversation))
        ]
      else
        render
      end
    end
    format.html { redirect_back fallback_location: @channel || @server }
  end
end
```

Note: Turbo `visit` might need a different approach. Alternative is to use Stimulus to navigate after form submission detects /msg pattern.

### 2. Make Usernames Clickable in User List

Update `app/views/channels/_user_list_content.html.erb` (or wherever user items are rendered):

```erb
<li class="user <%= "-op" if user.mode.include?("o") %> <%= "-voice" if user.mode.include?("v") %>">
  <%= link_to user.nickname,
              new_server_conversation_path(@channel.server, target_nick: user.nickname),
              data: { turbo_method: :post },
              class: "username-link" %>
</li>
```

### 3. Make Usernames Clickable in Messages

Update `app/views/messages/_message.html.erb`:

```erb
<span class="sender">
  <%= link_to message.sender,
              new_server_conversation_path(message.server, target_nick: message.sender),
              data: { turbo_method: :post },
              class: "sender-link" %>
</span>
```

### 4. Create Conversations#create Action

Add route and controller action to create conversation and redirect:

In `config/routes.rb`:
```ruby
resources :servers do
  resources :conversations, only: [:show, :create]
end
```

In `app/controllers/conversations_controller.rb`:

```ruby
def create
  @conversation = @server.conversations.find_or_create_by!(target_nick: params[:target_nick])
  redirect_to conversation_path(@conversation)
end
```

### 5. Style Username Links

Add CSS for clickable usernames:

```css
.sender-link,
.username-link {
  color: inherit;
  text-decoration: none;
  cursor: pointer;
}

.sender-link:hover,
.username-link:hover {
  text-decoration: underline;
  color: var(--color-primary);
}
```

## Tests

### Controller Tests

**POST /servers/:server_id/conversations creates conversation**
- Given: Server exists with connected user
- When: POST with target_nick "bob"
- Then: Conversation is created with target_nick "bob"
- And: Redirects to conversation show page

**POST /servers/:server_id/conversations finds existing conversation**
- Given: Conversation with "bob" already exists
- When: POST with target_nick "bob"
- Then: No new conversation created
- And: Redirects to existing conversation

**/msg command creates conversation**
- Given: User in #channel
- When: POST message with content "/msg bob hello"
- Then: Conversation created for "bob"
- And: Message created with target "bob"

**/msg updates conversation last_message_at**
- Given: Existing conversation with bob from yesterday
- When: POST message with content "/msg bob hi again"
- Then: Conversation.last_message_at is updated to now

### System Tests

**Click username in user list opens DM**
- Given: User viewing channel with "bob" in user list
- When: User clicks on "bob"
- Then: Navigates to DM conversation with bob
- And: Conversation appears in sidebar

**Click username in message opens DM**
- Given: User viewing channel with message from "alice"
- When: User clicks on "alice" sender name
- Then: Navigates to DM conversation with alice

**/msg command from channel**
- Given: User in #general
- When: User types "/msg bob hey there" and submits
- Then: Message is sent to bob
- And: "bob" DM appears in sidebar

### Integration Tests

**/msg then view conversation**
- Send /msg bob hello from #channel
- Navigate to bob's conversation
- Message "hello" should be visible in conversation

## Dependencies

- Requires feature 35 (Fix Sidebar Live Updates) for sidebar to show new conversations in real-time
