# Channel Name Links to Show Page

## Description

For debugging purposes, make the channel name in the server page channel list clickable so it always links to the channel show page, regardless of whether the user is joined.

Currently:
- Joined channels have a "View" button
- Not-joined channels have a "Join" button but no way to view the channel

## Behavior

On the server show page (`/servers/:id`), the channel name should be a link to the channel show page (`/channels/:id`).

This is in addition to the existing "View" button for joined channels.

## Views

Update `servers/show.html.erb` (or the extracted `servers/_channels.html.erb` partial):

Change:
```erb
<span class="name"><%= channel.name %></span>
```

To:
```erb
<%= link_to channel.name, channel_path(channel), class: "name" %>
```

## Tests

### Integration Tests

**Channel name links to channel show page**
- Given: User on server page with channel #ruby (joined)
- Then: Channel name "#ruby" is a link to /channels/:id

**Channel name links to show even when not joined**
- Given: User on server page with channel #ruby (not joined)
- Then: Channel name "#ruby" is a link to /channels/:id

### System Tests

**Clicking channel name navigates to channel view**
- Given: User on server page
- When: User clicks channel name
- Then: Browser navigates to channel show page

## Implementation Notes

- Simple change - just wrap the channel name in a link
- Keep the "View" button as well for clarity (link on name is bonus)

## Dependencies

None - simple UI change.
