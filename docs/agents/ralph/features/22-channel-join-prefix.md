# Channel Join Form Prefix Handling

## Description

When joining a channel, users may type the channel name with or without the `#` prefix. The form should handle both cases gracefully:
- `#channel` → join `#channel`
- `channel` → join `#channel` (prepend #)

Currently, if a user types `channel` without the `#`, the Channel model validation fails because it requires names to start with `#` or `&`.

## Behavior

### Join Flow

1. User types channel name in join form (e.g., "general" or "#general")
2. `ChannelsController#create` receives the name
3. **NEW**: Controller normalizes the name by prepending `#` if not already present
4. Channel is found or created with normalized name
5. JOIN command sent to IRC with normalized name

### Normalization Rules

- If name starts with `#` or `&`, use as-is
- If name doesn't start with `#` or `&`, prepend `#`
- Strip leading/trailing whitespace

## Implementation Notes

- Add a `normalize_channel_name` private method to `ChannelsController`
- Call it before `find_or_initialize_by`
- Could also add this as a model callback, but controller is simpler and keeps the validation strict

## Tests

### Controller Tests

**Join with # prefix works**
- Given: Connected server
- When: POST to `/servers/:id/channels` with `channel[name]=#test`
- Then: Channel created with name `#test`
- And: Redirects to channel page

**Join without # prefix prepends #**
- Given: Connected server
- When: POST to `/servers/:id/channels` with `channel[name]=test`
- Then: Channel created with name `#test`
- And: Redirects to channel page

**Join with & prefix works**
- Given: Connected server
- When: POST to `/servers/:id/channels` with `channel[name]=&local`
- Then: Channel created with name `&local`

**Join with whitespace is trimmed**
- Given: Connected server
- When: POST to `/servers/:id/channels` with `channel[name]=  #test  `
- Then: Channel created with name `#test`

**Join without prefix and with whitespace**
- Given: Connected server
- When: POST to `/servers/:id/channels` with `channel[name]=  test  `
- Then: Channel created with name `#test`

### Integration Tests

**User joins channel without typing #**
- Given: User on connected server page
- When: User types "general" in join form and submits
- Then: User is redirected to #general channel page
- And: JOIN command was sent for #general

## Dependencies

None.
