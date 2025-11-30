# Channel Management

## Description

Users can join and leave IRC channels. The app tracks which channels the user is in and displays them in the sidebar.

Joining/leaving happens via the internal API - this feature covers the UI and data management.

## Behavior

### Channel List (Sidebar)

- Shows all channels grouped by server
- Each channel shows:
  - Channel name (#ruby)
  - Unread indicator (dot or highlight) if has unread messages
  - Notification badge if has unread highlights/DMs
- Clicking a channel navigates to channel view
- Server header shows server name and connection status

### Join Channel

- Input field on server page or in sidebar
- User types channel name (e.g., "#ruby")
- Submit sends join command via `InternalApiClient.send_command`
- On successful join (join event via internal API):
  - Channel record created with `joined: true`
  - Channel appears in sidebar
  - Navigate to channel view

### Leave Channel

- "Leave" button or link on channel view
- Sends part command via `InternalApiClient.send_command`
- On successful part (part event via internal API):
  - Channel record updated with `joined: false`
  - Channel removed from active sidebar (but kept for history)
  - Navigate to server view

### Channel View

- Located at `/channels/:id`
- Shows:
  - Channel header (name, topic)
  - Message list (scrollable, newest at bottom)
  - Message input at bottom
  - User list in sidebar (optional, can be toggled)

### Channel Topic

- Displayed in channel header
- Updated when TOPIC event received from IRC
- User can see but not edit (editing is future feature)

## Models

### Channel

```ruby
class Channel < ApplicationRecord
  belongs_to :server
  has_many :channel_users, dependent: :destroy
  has_many :messages, dependent: :destroy
  
  validates :name, presence: true, format: { with: /\A[#&]/ }
  validates :name, uniqueness: { scope: :server_id }
  
  def unread_count
    return 0 unless last_read_message_id
    messages.where("id > ?", last_read_message_id).count
  end
  
  def has_unread?
    unread_count > 0
  end
  
  def mark_as_read
    update(last_read_message_id: messages.maximum(:id))
  end
end
```

### ChannelUser

Tracks who is in the channel (for user list display).

```ruby
class ChannelUser < ApplicationRecord
  belongs_to :channel
  
  validates :nickname, presence: true
  validates :nickname, uniqueness: { scope: :channel_id }
  
  scope :ops, -> { where("modes LIKE ?", "%o%") }
  scope :voiced, -> { where("modes LIKE ?", "%v%") }
  scope :regular, -> { where("modes NOT LIKE ? AND modes NOT LIKE ?", "%o%", "%v%") }
  
  def op?
    modes&.include?("o")
  end
  
  def voiced?
    modes&.include?("v")
  end
end
```

## Event Handling

Channel events (join, part, names) are handled by `IrcEventHandler` - see `07-messages-receive.md` for full implementation.

## Tests

### Controller: ChannelsController

**GET /channels/:id**
- Returns 200
- Shows channel name and messages

**User can only view their own channels**
- Create channel for User A
- Sign in as User B
- GET /channels/:id
- Returns 404 or redirect (not found for this user)

### Controller: ChannelsController (create/destroy)

**POST /servers/:server_id/channels**
- Params: { name: "#ruby" }
- Sends join command via InternalApiClient
- Creates/finds channel record
- Redirects to channel show

**DELETE /channels/:id**
- Sends part command via InternalApiClient
- Updates channel.joined to false
- Redirects to server show

### Model: Channel

**Validates name presence**
**Validates name starts with # or &**
**Validates uniqueness of name per server**
**unread_count returns 0 when no last_read_message_id**
**unread_count returns count of messages after last_read_message_id**
**mark_as_read updates last_read_message_id**

### Model: ChannelUser

**Validates nickname presence**
**Validates uniqueness of nickname per channel**
**op? returns true when modes includes o**
**voiced? returns true when modes includes v**

### Integration: Join Channel Flow

**User joins a channel**
- Have connected server
- Visit server page
- Enter "#ruby" in join field
- Submit
- POST to internal API sends join command
- Simulate join event via POST to /internal/irc/events
- See channel in sidebar
- See channel view with message list

**User leaves a channel**
- Have joined channel
- Visit channel page
- Click "Leave"
- POST to internal API sends part command
- Simulate part event via POST to /internal/irc/events
- Channel removed from sidebar
- Redirected to server page

### Integration: Channel User List

**Channel shows users**
- Have joined channel
- POST names event via /internal/irc/events
- Visit channel page
- See list of users
- Ops shown first (with @)
- Voiced shown next (with +)

## Routes

```ruby
resources :servers do
  resources :channels, only: [:create]
end

resources :channels, only: [:show, :destroy]
```

## Implementation Notes

- Channel membership vs. Channel: The channel record represents the channel itself (exists even after leaving for history). "Membership" is whether we're currently joined.
- Consider adding a `joined` boolean to Channel, or use presence of `left_at` timestamp
- User list can be in a Turbo Frame, lazy-loaded
- Sidebar updates via Turbo Stream when joining/leaving

## Dependencies

- Requires `03-server-crud.md` (Server model)
- Requires `04-internal-api.md` (InternalApiClient)
- Requires `05-irc-connections.md` (connection management)
