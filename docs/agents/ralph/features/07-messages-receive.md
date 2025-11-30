# Receiving Messages

## Description

IRC events arrive via the internal API at `/internal/irc/events`. The `IrcEventHandler` processes them, stores messages in the database, and Turbo Streams update the UI in real-time.

## Behavior

### Message Flow

1. IRC thread receives event from yaic
2. Thread POSTs to `/internal/irc/events` with event data
3. `EventsController` activates correct tenant (user's DB)
4. `IrcEventHandler` processes the event, creates records
5. Model callbacks broadcast via Turbo Stream
6. User's browser receives stream, DOM updates

### Event Types Handled

| Event Type | message_type | Description |
|------------|--------------|-------------|
| message | "privmsg" | Regular channel/PM message |
| action | "action" | /me action |
| notice | "notice" | IRC NOTICE |
| join | "join" | User joined channel |
| part | "part" | User left channel |
| quit | "quit" | User disconnected |
| kick | "kick" | User was kicked |
| nick | "nick" | User changed nickname |
| topic | "topic" | Channel topic changed |

### Event Payload Format

```json
{
  "server_id": 1,
  "user_id": 1,
  "event": {
    "type": "message",
    "data": {
      "source": "nick!user@host",
      "target": "#channel",
      "text": "Hello everyone"
    }
  }
}
```

### Private Messages

When someone sends us a private message (not to a channel):
- `channel_id` is null
- `target` field contains the other party's nickname
- Creates a Notification with reason "dm"

### Real-time Updates

Messages broadcast to Turbo Stream channels:
- Channel messages: broadcast to `channel_#{channel.id}`
- PMs: broadcast to `server_#{server.id}_pms`
- Server messages: broadcast to `server_#{server.id}_server`

## IrcEventHandler

Full implementation:

```ruby
# app/services/irc_event_handler.rb
class IrcEventHandler
  def self.handle(server, event)
    new(server, event).handle
  end

  def initialize(server, event)
    @server = server
    @event = event.with_indifferent_access
  end

  def handle
    case @event[:type]
    when "connected"
      handle_connected
    when "disconnected"
      handle_disconnected
    when "message"
      handle_message
    when "action"
      handle_action
    when "notice"
      handle_notice
    when "join"
      handle_join
    when "part"
      handle_part
    when "quit"
      handle_quit
    when "kick"
      handle_kick
    when "nick"
      handle_nick
    when "topic"
      handle_topic
    when "names"
      handle_names
    end
  end

  private

  def data
    @event[:data]
  end

  def source_nick
    data[:source]&.split("!")&.first || data[:source]
  end

  def handle_connected
    @server.update!(connected_at: Time.current)
  end

  def handle_disconnected
    @server.update!(connected_at: nil)
  end

  def handle_message
    target = data[:target]

    if channel_target?(target)
      channel = Channel.find_or_create_by!(server: @server, name: target)
      message = Message.create!(
        server: @server,
        channel: channel,
        sender: source_nick,
        content: data[:text],
        message_type: "privmsg"
      )

      check_highlight(message)
    else
      message = Message.create!(
        server: @server,
        channel: nil,
        target: source_nick,
        sender: source_nick,
        content: data[:text],
        message_type: "privmsg"
      )

      Notification.create!(message: message, reason: "dm")
    end
  end

  def handle_action
    target = data[:target]
    channel = Channel.find_or_create_by!(server: @server, name: target) if channel_target?(target)

    message = Message.create!(
      server: @server,
      channel: channel,
      target: channel ? nil : source_nick,
      sender: source_nick,
      content: data[:text],
      message_type: "action"
    )

    check_highlight(message) if channel
  end

  def handle_notice
    target = data[:target]
    channel = Channel.find_by(server: @server, name: target) if channel_target?(target)

    Message.create!(
      server: @server,
      channel: channel,
      target: channel ? nil : source_nick,
      sender: source_nick,
      content: data[:text],
      message_type: "notice"
    )
  end

  def handle_join
    channel = Channel.find_or_create_by!(server: @server, name: data[:target])

    if source_nick == @server.nickname
      channel.update!(joined: true)
    else
      channel.channel_users.find_or_create_by!(nickname: source_nick)
    end

    Message.create!(
      server: @server,
      channel: channel,
      sender: source_nick,
      message_type: "join"
    )
  end

  def handle_part
    channel = Channel.find_by(server: @server, name: data[:target])
    return unless channel

    if source_nick == @server.nickname
      channel.update!(joined: false)
      channel.channel_users.destroy_all
    else
      channel.channel_users.find_by(nickname: source_nick)&.destroy
    end

    Message.create!(
      server: @server,
      channel: channel,
      sender: source_nick,
      content: data[:text],
      message_type: "part"
    )
  end

  def handle_quit
    @server.channels.each do |channel|
      channel.channel_users.find_by(nickname: source_nick)&.destroy
    end

    Message.create!(
      server: @server,
      sender: source_nick,
      content: data[:text],
      message_type: "quit"
    )
  end

  def handle_kick
    channel = Channel.find_by(server: @server, name: data[:target])
    return unless channel

    kicked_nick = data[:kicked]
    channel.channel_users.find_by(nickname: kicked_nick)&.destroy

    Message.create!(
      server: @server,
      channel: channel,
      sender: source_nick,
      content: "#{kicked_nick} was kicked: #{data[:text]}",
      message_type: "kick"
    )
  end

  def handle_nick
    old_nick = source_nick
    new_nick = data[:new_nick]

    @server.channels.each do |channel|
      user = channel.channel_users.find_by(nickname: old_nick)
      user&.update!(nickname: new_nick)
    end

    Message.create!(
      server: @server,
      sender: old_nick,
      content: new_nick,
      message_type: "nick"
    )
  end

  def handle_topic
    channel = Channel.find_by(server: @server, name: data[:target])
    return unless channel

    channel.update!(topic: data[:text])

    Message.create!(
      server: @server,
      channel: channel,
      sender: source_nick,
      content: data[:text],
      message_type: "topic"
    )
  end

  def handle_names
    channel = Channel.find_by(server: @server, name: data[:channel])
    return unless channel

    channel.channel_users.destroy_all
    data[:names].each do |name|
      modes = ""
      nick = name

      if name.start_with?("@")
        modes = "o"
        nick = name[1..]
      elsif name.start_with?("+")
        modes = "v"
        nick = name[1..]
      end

      channel.channel_users.create!(nickname: nick, modes: modes)
    end
  end

  def channel_target?(target)
    target&.start_with?("#", "&")
  end

  def check_highlight(message)
    if message.content.downcase.include?(@server.nickname.downcase)
      Notification.create!(message: message, reason: "highlight")
    end
  end
end
```

## Models

### Message

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
      broadcast_append_to [server, :pms], target: "pm_messages"
    else
      broadcast_append_to [server, :server], target: "server_messages"
    end
  end
end
```

## Tests

### Controller: Internal::Irc::EventsController

Testing via the internal API is the primary way to test message receiving. No need to mock IRC connections.

**POST /internal/irc/events with message event**
- POST with message event payload
- Assert Message created with correct attributes
- Assert Turbo broadcast sent

**POST /internal/irc/events with PM creates notification**
- POST with message event where target is not a channel
- Assert Message created with target set
- Assert Notification created with reason "dm"

**POST /internal/irc/events with join event**
- POST with join event payload
- Assert ChannelUser created
- Assert Message created with type "join"

**POST /internal/irc/events with part event**
- POST with part event payload
- Assert ChannelUser destroyed
- Assert Message created with type "part"

**POST /internal/irc/events with topic event**
- POST with topic event payload
- Assert Channel.topic updated
- Assert Message created with type "topic"

**POST /internal/irc/events with names event**
- POST with names event payload (list of nicks)
- Assert ChannelUsers created with correct modes

### Unit: IrcEventHandler

**handle_message creates channel message**
- Call with message event for #channel
- Assert Message created with correct attributes

**handle_message creates PM with notification**
- Call with message event for non-channel target
- Assert Message created with target set
- Assert Notification created with reason "dm"

**handle_message detects highlight**
- Call with message containing server nickname
- Assert Notification created with reason "highlight"

**handle_join marks channel as joined when we join**
- Call with join event where source is our nick
- Assert channel.joined is true

**handle_part marks channel as not joined when we part**
- Call with part event where source is our nick
- Assert channel.joined is false
- Assert all channel_users destroyed

**handle_quit removes user from all channels**
- User is in multiple channels
- Call with quit event
- Assert user removed from all channels

### Model: Message

**after_create broadcasts to channel stream**
- Create message with channel
- Assert broadcast sent to channel stream

**after_create broadcasts PM to pms stream**
- Create message with target, no channel
- Assert broadcast sent to server pms stream

### Integration: Receive Message

**Message appears in real-time**
- User viewing channel page
- POST to internal events API with message
- Assert message appears in UI via Turbo Stream

## Implementation Notes

- All event handling happens in tenant context (controller switches tenant before calling handler)
- Source nick is extracted from IRC hostmask format (nick!user@host)
- Highlight detection is case-insensitive
- NAMES event replaces all channel users (full sync)
- QUIT events affect all channels the user was in

## Dependencies

- Requires `04-internal-api.md` (internal API)
- Requires `06-channels.md` (Channel model)
- Requires `02-auth-multitenant.md` (tenant switching)
