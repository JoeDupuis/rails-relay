# Receiving Messages

## Description

The IRC process receives messages from IRC servers and stores them in the database. The web UI updates in real-time via Solid Cable / Turbo Streams.

This covers the flow from IRC server → IRC process → database → browser.

## Behavior

### Message Flow

1. IRC server sends PRIVMSG (or other event) to our IRC process
2. IRC process parses the message
3. IRC process activates the correct tenant (user's DB)
4. IRC process creates Message record
5. Model callback broadcasts via Turbo Stream
6. User's browser receives stream, DOM updates
7. Message appears in channel view

### Message Types Handled

| IRC Event | message_type | content field |
|-----------|--------------|---------------|
| PRIVMSG | "privmsg" | Message text |
| PRIVMSG with CTCP ACTION | "action" | Action text (stripped of CTCP markers) |
| NOTICE | "notice" | Notice text |
| JOIN | "join" | null |
| PART | "part" | Part message (optional) |
| QUIT | "quit" | Quit message (optional) |
| KICK | "kick" | Kick reason |
| NICK | "nick" | New nickname |
| TOPIC | "topic" | New topic |
| MODE | "mode" | Mode string |
| Server messages (001, 002, MOTD, etc.) | "server" | Message text |

### Private Messages

When someone sends us a private message (not to a channel):
- `channel_id` is null
- `target` field contains the other party's nickname
- Creates a Notification with reason "dm"

### Handling Each Event Type

**PRIVMSG to channel:**
```
:nick!user@host PRIVMSG #channel :Hello everyone
```
- Find or create Channel for #channel
- Create Message(channel: channel, sender: "nick", content: "Hello everyone", message_type: "privmsg")

**PRIVMSG to us (PM):**
```
:nick!user@host PRIVMSG ourmick :Hey there
```
- Create Message(channel: nil, target: "nick", sender: "nick", content: "Hey there", message_type: "privmsg")
- Create Notification(message: message, reason: "dm")

**ACTION:**
```
:nick!user@host PRIVMSG #channel :\x01ACTION waves\x01
```
- Detect CTCP ACTION wrapper
- Create Message(message_type: "action", content: "waves")

**JOIN:**
```
:nick!user@host JOIN #channel
```
- Find or create Channel
- Add ChannelUser record
- Create Message(message_type: "join", sender: "nick")

**PART:**
```
:nick!user@host PART #channel :Goodbye
```
- Find Channel
- Remove ChannelUser record
- Create Message(message_type: "part", sender: "nick", content: "Goodbye")

**TOPIC:**
```
:nick!user@host TOPIC #channel :New topic here
```
- Update Channel.topic
- Create Message(message_type: "topic", sender: "nick", content: "New topic here")

### Real-time Updates

Messages broadcast to Turbo Stream channels:
- Channel messages: broadcast to `channel_#{channel.id}`
- PMs: broadcast to `server_#{server.id}_pms`
- Server messages: broadcast to `server_#{server.id}_server`

## Models

### Message

See `docs/agents/data-model.md`. Key callbacks:

```ruby
class Message < ApplicationRecord
  belongs_to :server
  belongs_to :channel, optional: true
  has_one :notification, dependent: :destroy

  after_create_commit :broadcast_message

  private

  def broadcast_message
    if channel
      broadcast_append_to channel, target: "messages"
    elsif target.present?
      # PM - broadcast to PMs stream
      broadcast_append_to [server, :pms], target: "pm_messages"
    else
      # Server message
      broadcast_append_to [server, :server], target: "server_messages"
    end
  end
end
```

## IRC Process Implementation

```ruby
# In IrcProcess

def setup_handlers
  @client.on(:privmsg) { |event| handle_privmsg(event) }
  @client.on(:notice) { |event| handle_notice(event) }
  @client.on(:join) { |event| handle_join(event) }
  @client.on(:part) { |event| handle_part(event) }
  @client.on(:quit) { |event| handle_quit(event) }
  @client.on(:kick) { |event| handle_kick(event) }
  @client.on(:nick) { |event| handle_nick(event) }
  @client.on(:topic) { |event| handle_topic(event) }
  @client.on(:mode) { |event| handle_mode(event) }
  @client.on(:raw) { |line| handle_raw(line) }
end

def handle_privmsg(event)
  Tenant.switch(@server.user) do
    if event.target.start_with?("#", "&")
      # Channel message
      channel = Channel.find_or_create_by!(server: @server, name: event.target)
      
      message_type = event.action? ? "action" : "privmsg"
      content = event.action? ? event.action_text : event.message
      
      message = Message.create!(
        server: @server,
        channel: channel,
        sender: event.nick,
        content: content,
        message_type: message_type
      )
      
      # Check for highlight
      if content.downcase.include?(@server.nickname.downcase)
        Notification.create!(message: message, reason: "highlight")
      end
    else
      # Private message to us
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
end
```

## Tests

### Model: Message

**after_create broadcasts to channel stream**
- Create message with channel
- Assert broadcast sent to channel stream

**after_create broadcasts PM to pms stream**
- Create message with target, no channel
- Assert broadcast sent to server pms stream

**after_create broadcasts server message to server stream**
- Create message with no channel, no target
- Assert broadcast sent to server stream

### Model: Message Associations

**belongs_to server (required)**
**belongs_to channel (optional)**
**has_one notification**

### Integration: Receive Channel Message

**Message appears in real-time**
- User viewing channel page
- IRC process receives PRIVMSG for that channel
- Message appears in UI without refresh

(This is hard to test without simulating IRC. May need to test the model/broadcast layer separately and trust the IRC process calls it correctly.)

### Unit: IRC Process Handlers

**handle_privmsg creates channel message**
- Simulate PRIVMSG event to #channel
- Assert Message created with correct attributes
- Assert channel found/created

**handle_privmsg creates PM with notification**
- Simulate PRIVMSG event to our nick
- Assert Message created with target set
- Assert Notification created with reason "dm"

**handle_privmsg detects ACTION**
- Simulate PRIVMSG with CTCP ACTION
- Assert message_type is "action"
- Assert content has ACTION markers stripped

**handle_privmsg detects highlight**
- Simulate PRIVMSG containing our nickname
- Assert Notification created with reason "highlight"

**handle_join creates message and channel_user**
- Simulate JOIN event
- Assert Message created with type "join"
- Assert ChannelUser created

**handle_part removes channel_user**
- Have existing ChannelUser
- Simulate PART event
- Assert ChannelUser destroyed
- Assert Message created with type "part"

**handle_topic updates channel**
- Simulate TOPIC event
- Assert Channel.topic updated
- Assert Message created with type "topic"

## Implementation Notes

- IRC process must activate tenant before any DB operations
- CTCP ACTION format: `\x01ACTION text\x01` - strip the markers
- Highlight detection is case-insensitive
- For QUIT events, the user quits all channels - need to remove from all ChannelUser records
- Server messages (numeric replies) can be high volume during connect - consider batching or filtering

## Dependencies

- Requires `process-spawn.md` (IRC process exists)
- Requires `process-ipc.md` (process can write to DB)
- Requires `channels.md` (Channel model exists)
