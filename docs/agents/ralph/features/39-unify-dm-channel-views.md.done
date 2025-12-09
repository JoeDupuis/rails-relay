# Unify DM and Channel Views

## Description

Currently, DMs (`conversations/show.html.erb`) and channels (`channels/show.html.erb`) use different view structures. The channel view uses shared partials for header, banner, and input, while the DM view has everything inline. This makes maintenance harder and creates inconsistent UX.

Refactor the DM view to use the same structure and shared partials as the channel view.

## Current State

**Channel view** (`channels/show.html.erb`):
- Uses `channels/_header.html.erb` partial
- Uses `channels/_banner.html.erb` partial
- Uses `channels/_input.html.erb` partial
- Uses `channels/_user_list.html.erb` via `content_for :userlist`
- Has `data-controller="channel"` on container

**DM view** (`conversations/show.html.erb`):
- Has inline header with target_nick and "Direct Message" label
- Has inline message form
- Has "Back to Server" link
- No user list (DMs are 1:1)
- No banner

## Target State

Both views should use the same structure with polymorphic partials that work for either context.

## Behavior

### Shared View Structure

Create a unified view structure that works for both channels and DMs:

1. **Header partial** - Shows name/topic for channels, target_nick/"Direct Message" for DMs
2. **Messages area** - Already uses same `messages/_message.html.erb` partial
3. **Input partial** - Form to send messages (already similar logic)
4. **User list** - Only shown for channels (DMs don't have a user list)

### Implementation Approach

Option A: Make channel partials polymorphic (accept either channel or conversation)
Option B: Create shared partials in `shared/` that both use
Option C: Create a presenter/decorator that normalizes the interface

Recommended: **Option A** - Modify existing channel partials to accept a `messageable` local that can be either a Channel or Conversation. This minimizes new files and keeps things DRY.

### Partial Changes

**`channels/_header.html.erb`** → accepts `messageable`:
- If Channel: show channel name, topic, auto-join toggle, leave/join button, user count button
- If Conversation: show target_nick, "Direct Message" subtitle, no auto-join, no leave button, no user count

**`channels/_input.html.erb`** → accepts `messageable`:
- If Channel: check `server.connected?` and `channel.joined?`
- If Conversation: check `server.connected?` only
- Form posts to appropriate path based on type

**`conversations/show.html.erb`**:
- Use same structure as `channels/show.html.erb`
- Render shared partials with `messageable: @conversation`
- No `content_for :userlist` (DMs don't have user lists)

### Duck Typing

Both Channel and Conversation should respond to:
- `server` - returns the Server
- `name` (or add method to Conversation) - returns display name

Add to Conversation model:
```ruby
def display_name
  target_nick
end

def subtitle
  "Direct Message"
end
```

Add to Channel model:
```ruby
def display_name
  name
end

def subtitle
  topic
end
```

## Models

### Conversation

Add helper methods:
- `display_name` - returns `target_nick`
- `subtitle` - returns "Direct Message"

### Channel

Add helper methods:
- `display_name` - returns `name`
- `subtitle` - returns `topic`

## Tests

### Model Tests

**Conversation#display_name**
- Given: conversation with target_nick "alice"
- When: calling display_name
- Then: returns "alice"

**Conversation#subtitle**
- Given: any conversation
- When: calling subtitle
- Then: returns "Direct Message"

**Channel#display_name**
- Given: channel with name "#ruby"
- When: calling display_name
- Then: returns "#ruby"

**Channel#subtitle**
- Given: channel with topic "Ruby discussion"
- When: calling subtitle
- Then: returns "Ruby discussion"

### System Tests

**DM view renders correctly**
- Given: user is logged in with a server and existing conversation
- When: visiting the conversation page
- Then: see target_nick in header
- And: see "Direct Message" subtitle
- And: see message input form
- And: do NOT see user list toggle button
- And: do NOT see auto-join checkbox
- And: do NOT see leave button

**Channel view still works**
- Given: user is logged in with a server and joined channel
- When: visiting the channel page
- Then: see channel name in header
- And: see topic as subtitle
- And: see message input form
- And: see user list toggle button
- And: see auto-join checkbox
- And: see leave button

**DM message sending still works**
- Given: user is viewing a DM conversation with connected server
- When: typing a message and submitting
- Then: message appears in the conversation

## Implementation Notes

- The header partial will need conditional logic based on `messageable.is_a?(Channel)` or duck typing checks
- Keep the existing Turbo Stream subscriptions working - channels subscribe to `@channel` and `[@channel, :users]`, DMs subscribe to `[@server, :dm, @conversation.target_nick.downcase]`
- The "Back to Server" link in current DM view can be removed - navigation is via sidebar
- Test that mobile drawer button does NOT appear for DMs (no users to show)

## Dependencies

None - this is a refactor of existing functionality.
