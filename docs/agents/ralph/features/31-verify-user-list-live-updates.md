# Verify User List Live Updates

## Description

When other users join or leave a channel, the user list should update in real-time. Currently reported as not working.

The existing implementation has:
- `ChannelUser` model with `after_create_commit`, `after_destroy_commit` callbacks that broadcast
- `IrcEventHandler` handles join/part/quit events and creates/destroys ChannelUser records
- Channel view subscribes to `turbo_stream_from @channel, :users`

This feature is to investigate why it's not working and fix it.

## Investigation Steps

### Step 1: Verify yaic emits events for other users

In yaic's `client.rb`, check that:
- `:join` event is emitted when ANY user joins (not just ourselves)
- `:part` event is emitted when ANY user leaves
- `:quit` event is emitted when users quit

Looking at yaic's `emit_events` method and `build_event_attributes`:
```ruby
when :join
  {channel: message.params[0], user: message.source}
```

This should emit for all users. **If yaic is not emitting events for other users, use `AskUserQuestion` to pause and report this as a yaic issue.**

### Step 2: Verify IrcConnection forwards events

Check that `setup_handlers` registers handlers for join/part/quit and that these events are forwarded to the Rails app via `@on_event.call`.

### Step 3: Verify IrcEventHandler creates/destroys ChannelUser

- `handle_join`: Creates ChannelUser for non-self users
- `handle_part`: Destroys ChannelUser for non-self users
- `handle_quit`: Destroys ChannelUser across all channels

### Step 4: Verify Turbo Stream broadcasts

- ChannelUser callbacks call `broadcast_replace_to([channel, :users], ...)`
- Channel view subscribes to `turbo_stream_from @channel, :users`

Check the subscription format matches the broadcast target.

### Step 5: Verify the partial renders correctly

The partial `channels/_user_list.html.erb` should render all channel_users.

## Likely Issues

1. **Turbo Stream subscription mismatch**: The broadcast is to `[channel, :users]` but the subscription might not match
2. **Missing Turbo subscription in view**: Double-check `<%= turbo_stream_from @channel, :users %>` exists
3. **yaic not emitting events**: Would need fix in yaic gem

## Tests

### Integration Tests

**User list updates when another user joins**
- Given: User viewing channel #ruby
- When: IrcEventHandler processes join event for "newuser"
- Then: "newuser" appears in the user list

**User list updates when another user parts**
- Given: User viewing channel #ruby with "otheruser" in channel
- When: IrcEventHandler processes part event for "otheruser"
- Then: "otheruser" no longer in user list

**User list updates when another user quits**
- Given: User viewing channel #ruby with "otheruser" in channel
- When: IrcEventHandler processes quit event for "otheruser"
- Then: "otheruser" no longer in user list

### System Tests

**User list updates in real-time**
- Given: Browser on channel #ruby page
- When: Server sends JOIN event for "newuser" (via test helper)
- Then: User list shows "newuser" without page refresh

## Implementation Notes

If investigation reveals the issue is in yaic gem:
1. Use `AskUserQuestion` tool to report: "The yaic gem is not emitting join/part/quit events for other users. This needs to be fixed in yaic before this feature can work."
2. Do not attempt to fix yaic - pause and wait for instructions.

If the issue is in rails_relay, fix it according to findings.

## Dependencies

None - this is investigation and bug fix.
