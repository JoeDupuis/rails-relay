# Sending Messages

## Description

Users send messages through the web UI. The message is sent via the internal API to the IRC connection, which forwards it to the IRC server. The message is also stored locally for immediate display.

## Behavior

### Send Flow

1. User types message in input field
2. User presses Enter or clicks Send
3. Form submits to MessagesController#create
4. Controller creates Message record (our own message, for immediate UI feedback)
5. Controller sends command via `InternalApiClient.send_command`
6. IRC connection receives command, sends PRIVMSG to IRC server
7. Message appears in UI via Turbo Stream (from model callback)

### Message Input

- Text input at bottom of channel view
- Placeholder: "Message #channel" or "Message nickname"
- Submit on Enter (Shift+Enter for newline if supporting multi-line)
- Send button (optional, for mobile)
- Disabled when not connected to server

### Creating the Message Locally

When user sends a message, we create the Message record ourselves (don't wait for echo from server):
- sender: our nickname
- content: the message
- message_type: "privmsg" (or "action" if /me command)
- channel: current channel (or nil for PM)
- target: recipient nick (for PM)

### Commands

Support basic IRC commands in the input:

| Input | Action |
|-------|--------|
| `/me does something` | Send as ACTION |
| `/msg nick message` | Send PM to nick |
| `/notice target message` | Send NOTICE |
| `/nick newnick` | Change nickname |
| `/topic new topic` | Set channel topic (if op) |
| `/join #channel` | Join channel (handled by channels feature) |
| `/part` | Leave current channel |
| Regular text | Send as PRIVMSG to current target |

### Error Handling

- If server not connected: show error, don't send
- If IRC service unavailable: show error, message still created locally (for history)
- If message too long (IRC limit ~512 chars including protocol): truncate or warn

## Models

Message model already exists. For sending, we're creating messages where sender = our nickname.

```ruby
class Message < ApplicationRecord
  def from_me?(current_nickname)
    sender.downcase == current_nickname.downcase
  end
end
```

## Controller

```ruby
# app/controllers/messages_controller.rb
class MessagesController < ApplicationController
  def create
    @channel = Channel.find(params[:channel_id]) if params[:channel_id]
    @server = @channel&.server || Server.find(params[:server_id])

    content = params[:content]

    case content
    when /\A\/me (.+)/
      send_action(@channel || params[:target], $1)
    when /\A\/msg (\S+) (.+)/
      send_pm($1, $2)
    when /\A\/notice (\S+) (.+)/
      send_notice($1, $2)
    when /\A\/nick (\S+)/
      change_nick($1)
    when /\A\/topic (.+)/
      set_topic($1)
    when /\A\/part/
      part_channel
    when /\A\//
      flash[:error] = "Unknown command"
      redirect_back fallback_location: @channel || @server
      return
    else
      send_message(@channel || params[:target], content)
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: @channel || @server }
    end
  end

  private

  def send_message(target, content)
    target_name = target.is_a?(Channel) ? target.name : target

    @message = Message.create!(
      server: @server,
      channel: target.is_a?(Channel) ? target : nil,
      target: target.is_a?(Channel) ? nil : target,
      sender: @server.nickname,
      content: content,
      message_type: "privmsg"
    )

    send_irc_command("privmsg", target: target_name, message: content)
  end

  def send_action(target, action_text)
    target_name = target.is_a?(Channel) ? target.name : target

    @message = Message.create!(
      server: @server,
      channel: target.is_a?(Channel) ? target : nil,
      target: target.is_a?(Channel) ? nil : target,
      sender: @server.nickname,
      content: action_text,
      message_type: "action"
    )

    send_irc_command("action", target: target_name, message: action_text)
  end

  def send_pm(nick, content)
    @message = Message.create!(
      server: @server,
      channel: nil,
      target: nick,
      sender: @server.nickname,
      content: content,
      message_type: "privmsg"
    )

    send_irc_command("privmsg", target: nick, message: content)
  end

  def send_notice(target, content)
    send_irc_command("notice", target: target, message: content)
  end

  def change_nick(new_nick)
    send_irc_command("nick", nickname: new_nick)
  end

  def set_topic(topic)
    return unless @channel
    send_irc_command("topic", channel: @channel.name, topic: topic)
  end

  def part_channel
    return unless @channel
    InternalApiClient.send_command(
      server_id: @server.id,
      command: "part",
      params: { channel: @channel.name }
    )
    redirect_to @server
  end

  def send_irc_command(command, **params)
    InternalApiClient.send_command(
      server_id: @server.id,
      command: command,
      params: params
    )
  rescue InternalApiClient::ConnectionNotFound
    flash[:alert] = "Server not connected"
  rescue InternalApiClient::ServiceUnavailable
    flash[:alert] = "IRC service unavailable"
  end
end
```

## Routes

```ruby
resources :channels do
  resources :messages, only: [:create]
end

resources :servers do
  resources :messages, only: [:create]
end
```

## Tests

### Controller: MessagesController#create

**POST /channels/:id/messages with content**
- Creates Message record
- Calls InternalApiClient.send_command
- Returns Turbo Stream

**POST with /me command**
- Creates Message with type "action"
- Content has /me stripped
- Sends action command

**POST with /msg command**
- Creates Message with target set, no channel
- Sends to correct nick

**POST with unknown command**
- Shows error
- Does not create message

**POST when server not connected**
- Stub InternalApiClient to raise ConnectionNotFound
- Creates message locally (for history)
- Shows error flash

**POST when IRC service unavailable**
- Stub InternalApiClient to raise ServiceUnavailable
- Creates message locally
- Shows error flash

### Integration: Send Message Flow

**User sends message to channel**
- View channel page
- Type message in input
- Submit
- Message appears in message list (via Turbo)
- Input is cleared
- POST to /internal/irc/commands was made (can verify via stub)

**User sends /me action**
- Type "/me waves"
- Submit
- Message appears with action styling

**User sends PM via /msg**
- Type "/msg othernick hello"
- Submit
- Message created for PM conversation

### Model: Message#from_me?

**returns true when sender matches nickname**
**returns true case-insensitively**
**returns false when sender is different**

## Implementation Notes

- Message is created BEFORE sending to IRC (optimistic UI)
- If IRC send fails, message still exists locally
- Clear input after send (Turbo Stream can do this)
- Disable input while sending to prevent double-submit
- IRC has message length limits - consider validation
- ACTION uses the "action" command, not CTCP wrapping (yaic handles that)

## Dependencies

- Requires `04-internal-api.md` (InternalApiClient)
- Requires `06-channels.md` (Channel model)
- Requires `07-messages-receive.md` (Message model with broadcasts)
