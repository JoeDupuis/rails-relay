# Nick Change Live Update

## Description

When the user changes their nickname (via /nick command), the UI should update in real-time without requiring a page refresh. Currently:
- The server page shows the old nickname until refresh
- The sidebar may show old nickname
- The header may show old nickname

Looking at existing code:
- `Server#broadcast_nickname_change` exists and broadcasts when `nickname` changes
- It targets `nickname_server_#{id}` which matches the ID in server show page

So the server page SHOULD update. Need to verify:
1. Is the broadcast working?
2. Are other places (sidebar, header) missing updates?

## Behavior

When nickname changes (via nick event from IRC):
1. Server page nickname updates (should already work)
2. Sidebar shows new nickname (if displayed there)
3. Any other places showing nickname update

## Investigation

### Places where nickname is displayed

1. **Server show page**: `<p class="nickname" id="<%= dom_id(@server, :nickname) %>">as <strong><%= @server.nickname %></strong></p>`
   - Has Turbo target, broadcast exists

2. **Sidebar**: Check `shared/_sidebar.html.erb` - does it show server nickname?

3. **Channel view**: The message input may reference nickname for display

4. **Header**: Check if header shows current server/nickname

### Verify broadcast is working

The broadcast targets `nickname_server_#{id}` but the view uses `dom_id(@server, :nickname)` which generates `nickname_server_1`.

Wait - looking at the server show view:
```erb
<p class="nickname" id="<%= dom_id(@server, :nickname) %>">
```

And the broadcast:
```ruby
target: "nickname_server_#{id}"
```

`dom_id(@server, :nickname)` generates `nickname_server_1` (for server id 1).
`"nickname_server_#{id}"` also generates `nickname_server_1`.

These should match. So the broadcast should work.

**Possible issue**: The broadcast goes to `self` (the server stream), which the server show page subscribes to. But does it work?

## Tests

### Integration Tests

**Nickname updates on server page via broadcast**
- Given: User viewing server page
- When: IrcEventHandler processes nick event for user's own nick change
- Then: Nickname display on page shows new nickname

**Server page nickname update without refresh**
- Given: User on server page, server nickname is "oldnick"
- When: Server.update!(nickname: "newnick")
- Then: Turbo Stream broadcast is sent
- And: Target is "nickname_server_#{id}"

### System Tests

**Nickname changes in real-time**
- Given: Browser on server page showing "oldnick"
- When: Nick change event is processed (via IrcEventHandler)
- Then: Page shows "newnick" without refresh

## Implementation Notes

This may be a verification feature - confirm existing code works, add missing pieces if needed.

If sidebar or other places need updates:
- Extract nickname display to a partial
- Add Turbo targets
- Add broadcasts to Server model

## Dependencies

- 31-verify-user-list-live-updates (may share Turbo Stream fixes)
