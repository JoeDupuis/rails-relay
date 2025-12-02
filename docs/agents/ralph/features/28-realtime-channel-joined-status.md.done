# Real-time Channel Joined Status Updates

## Description

When a user's channel joined status changes (via kick, forced join, part, or join), the UI should update in real-time without requiring a page refresh. Currently:
- The server show page channel list doesn't update when joined status changes
- The channel show page header (join/leave buttons) doesn't update
- The "not joined" banner doesn't appear/disappear

## Behavior

### Server Show Page

The channel list on `/servers/:id` should update in real-time when:
- We join a channel (joined: false → true)
- We leave/get kicked from a channel (joined: true → false)

Changes needed:
- Wrap the channel list in a Turbo target
- Add broadcast callback to Channel model when `joined` changes
- Broadcast replacement of the channel list section

### Channel Show Page

The channel header and banner should update when `joined` changes:
- Join/Leave button should swap
- "Not joined" banner should appear/disappear
- Message input should enable/disable

Changes needed:
- Wrap header in a Turbo target
- Wrap banner in a Turbo target
- Add broadcasts for these targets when channel.joined changes

## Models

Update `Channel` model to broadcast on joined status change:

```ruby
after_update_commit :broadcast_joined_status, if: :saved_change_to_joined?

private

def broadcast_joined_status
  # Broadcast to channel view (for users viewing this channel)
  broadcast_replace_to(
    self,
    target: dom_id(self, :header),
    partial: "channels/header",
    locals: { channel: self }
  )

  broadcast_replace_to(
    self,
    target: dom_id(self, :banner),
    partial: "channels/banner",
    locals: { channel: self }
  )

  broadcast_replace_to(
    self,
    target: dom_id(self, :input),
    partial: "channels/input",
    locals: { channel: self }
  )

  # Broadcast to server view (for users viewing the server page)
  broadcast_replace_to(
    server,
    target: dom_id(server, :channels),
    partial: "servers/channels",
    locals: { server: server, channels: server.channels.order(:name) }
  )
end
```

## Views

### Server Show Page

Extract channel list to partial `servers/_channels.html.erb`:
```erb
<section class="channels" id="<%= dom_id(server, :channels) %>">
  ...existing channel list markup...
</section>
```

### Channel Show Page

Extract to partials:
- `channels/_header.html.erb` - the header with name, topic, join/leave button
- `channels/_banner.html.erb` - the "not joined" banner (or empty when joined)
- `channels/_input.html.erb` - the message input area

Each partial wraps its content with the appropriate Turbo target ID.

## Tests

### Model Tests (Channel)

**broadcasts joined status change to channel stream**
- Given: Channel #ruby with joined: true
- When: channel.update!(joined: false)
- Then: broadcast_replace_to is called for header, banner, input targets

**broadcasts joined status change to server stream**
- Given: Channel #ruby on server
- When: channel.update!(joined: true)
- Then: broadcast_replace_to is called for server channels target

**does not broadcast when joined is unchanged**
- Given: Channel #ruby with joined: true
- When: channel.update!(topic: "new topic")
- Then: no broadcast for joined status

### Integration Tests

**Channel view updates when kicked**
- Given: User viewing channel #ruby (joined: true)
- When: IrcEventHandler processes kick event for user
- Then: Header shows "Join" button instead of "Leave"
- And: Banner shows "You are not in this channel"

**Channel view updates when force-joined**
- Given: User viewing channel #ruby (joined: false)
- When: IrcEventHandler processes join event for user's own nick
- Then: Header shows "Leave" button instead of "Join"
- And: Banner is not visible

**Server page updates channel list when joined**
- Given: User viewing server page with channel #ruby (not joined)
- When: IrcEventHandler processes join event for user
- Then: Channel row no longer shows "(not joined)" status
- And: Actions change from "Join" to "View/Leave"

**Server page updates channel list when kicked**
- Given: User viewing server page with channel #ruby (joined)
- When: IrcEventHandler processes kick event for user
- Then: Channel row shows "(not joined)" status
- And: Actions change from "View/Leave" to "Join"

## Implementation Notes

- Use `dom_id` helper for consistent Turbo target IDs
- The channel view already has `turbo_stream_from @channel` subscription
- The server view already has `turbo_stream_from @server` subscription
- Channel broadcasts to `self` stream, server broadcasts to `server` stream

## Dependencies

- 27-fix-kick-updates-joined-state (kick must update joined status first)
