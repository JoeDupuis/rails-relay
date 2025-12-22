# Progress Log

## Current State

Phase 12: UX Polish & Bug Fixes in progress.

## Suggested Next Feature

Start with `51-dm-offline-user-feedback.md` - Gray out input when DMing offline user.

## Pending Features

### Phase 12: UX Polish & Bug Fixes

47. `47-fix-flash-clearing-on-disconnect.md.done` - DONE - Removed unnecessary "Disconnecting..." flash (disconnect is instant)
48. `48-clickable-links-in-messages.md.done` - DONE - Make URLs in chat messages clickable
49. `49-sidebar-connection-indicator-update.md.done` - DONE - Sidebar connection indicator live update
50. `50-fix-dm-close-button-styling.md.done` - DONE - Fix DM close button always visible, unstyled
51. `51-dm-offline-user-feedback.md` - Gray out input when DMing offline user

### Phase 11: Bug Fixes & Refactoring (DONE)

43. `43-fix-file-uploads.md.done` - DONE - Fix broken file uploads by moving to Message model with has_one_attached
44. `44-fix-user-list-live-updates.md.done` - DONE - Fix NAMES event race condition by batching broadcasts
46. `46-move-services-to-models.md.done` - DONE - Move app/services to app/models per conventions

### Phase 10: DM & View Improvements (DONE)

39. `39-unify-dm-channel-views.md.done` - DONE - Refactor DM view to share partials with channel view
40. `40-dm-user-online-status.md.done` - DONE - Show online/offline indicator for DM users in sidebar
41. `41-close-dm-conversations.md.done` - DONE - Add ability to close DMs (hide from sidebar, auto-reopen on new message)
42. `42-unify-userlist-partial.md.done` - DONE - Single user list partial for desktop/mobile (fixes live update issue)

### Phase 9: UX Improvements & Mobile Support (DONE)

34. `34-fix-message-auto-scroll.md.done` - DONE - Fix auto-scroll to bottom on new messages
35. `35-fix-sidebar-live-updates.md.done` - DONE - Fix sidebar not updating when channels join or DMs arrive
36. `36-fix-server-page-layout.md.done` - DONE - Fix server page layout on mobile viewports
37. `37-mobile-userlist-drawer.md.done` - DONE - Add user list drawer for mobile
38. `38-dm-initiation.md.done` - DONE - Click username to DM, fix /msg command

### Deferred

33. `33-list-public-channels.md.deferred` - DEFERRED (requires yaic LIST support)

---

## Completed Features

The application now has:
- User authentication
- Sidebar live updates (DMs, channel join/leave, unread counts)
- Server management (CRUD)
- IRC connections via internal API
- Channels (join, leave, list)
- Messages (send, receive, history)
- Real-time connection status updates
- Private messages
- Notifications and highlights
- Complete UI layout
- Media uploads
- Nickname change sync
- Channel joined state reset on disconnect
- Auto-join channels on reconnect
- Connection health check (detects stale connections)
- Message send failure handling (graceful error recovery)
- Kick event updates channel joined status
- Real-time channel joined status updates (broadcasts UI changes)
- Connection timeout handling (graceful recovery on connect timeout)
- Nick change live update (real-time nickname updates in UI)
- User list live updates (join/part/quit/kick update user list in real-time)
- Mobile user list drawer (slide-in drawer for viewports < 1024px)
- Message auto-scroll (auto-scroll to bottom on new messages, preserve position when reading history)
- DM initiation (click username to start DM, /msg creates conversation)
- Close DM conversations (hide from sidebar, auto-reopen on new message)
- Unified user list partial (single DOM element for desktop/mobile, live updates work on both)

---

## Feature Overview

### Phase 1: Authentication & Foundation
1. `01-auth-signin.md` - User login via Rails auth generator
2. ~~`02-auth-multitenant.md` - Per-user database isolation~~ (Removed - now using standard Rails associations)

### Phase 2: Server Management
3. `03-server-crud.md` - Add, edit, delete IRC servers (Server belongs_to :user)

### Phase 3: IRC Process
4. `04-process-spawn.md` - Spawning and managing IRC processes
5. `05-process-ipc.md` - Communication between Rails and IRC processes

### Phase 4: Channels & Messages
6. `06-channels.md` - Join, leave, list channels
7. `07-messages-receive.md` - Receiving messages from IRC
8. `08-messages-send.md` - Sending messages to IRC
9. `09-messages-history.md` - Message history and scrollback
10. `10-pm-view.md` - Private message conversations

### Phase 5: Notifications
11. `11-notifications-unread.md` - Unread tracking and badges
12. `12-notifications-highlights.md` - Highlights and browser notifications

### Phase 6: UI
13. `13-ui-layout.md` - Main application layout
14. `14-ui-server-view.md` - Server details page
15. `15-ui-channel-view.md` - Channel message view

### Phase 7: Media
16. `16-media-upload.md` - Image upload via ActiveStorage

### Phase 11: Bug Fixes & Refactoring
43. `43-fix-file-uploads.md` - Fix broken file uploads (move to Message model)
44. `44-fix-user-list-live-updates.md` - Fix user list live updates regression
46. `46-move-services-to-models.md` - Move services/ to models/ per conventions

---

## Session History

### Session 2025-12-22 (continued)

**Feature**: 50-fix-dm-close-button-styling
**Status**: Completed

**What was done**:
- Fixed CSS selectors in `dm-item.css` to target close button through form wrapper
- Added `& > form { display: contents; }` to preserve flex layout
- Updated selectors from `& > .close-btn` to `& > form > .close-btn`
- Added 4 system tests for styling behavior:
  - `test_close_button_hidden_by_default` (opacity: 0)
  - `test_close_button_appears_on_DM_item_hover` (opacity: 1)
  - `test_close_button_styled_without_button_chrome` (no background/border)
  - `test_close_button_changes_color_on_hover` (color changes)
- All 79 system tests pass
- Pre-existing ISON test failures and rubocop errors unrelated
- Passed QA review

**Notes for next session**:
- The root cause was `button_to` generating a `<form>` wrapper, breaking direct child selectors
- `display: contents` makes the form invisible to flex layout
- Next feature is 51-dm-offline-user-feedback.md

---

### Session 2025-12-22 (continued)

**Feature**: 49-sidebar-connection-indicator-update
**Status**: Completed

**What was done**:
- Created `_connection_indicator.html.erb` partial with Turbo Stream target ID
- Updated `_sidebar.html.erb` to use the new partial
- Added sidebar broadcast to `Server#broadcast_connection_status` using `user_id` (works in background job context)
- Added 2 model tests for sidebar broadcast on connect/disconnect
- Added 2 integration tests for IrcEventHandler broadcasting to sidebar stream
- Created system test file with 2 tests for real-time sidebar indicator updates
- All 488 unit tests pass (2 pre-existing ISON errors unrelated)
- All 76 system tests pass
- Passed QA review

**Notes for next session**:
- Pre-existing ISON test failures in internal_api_client_test.rb (test stubs use incorrect URL format)
- Next feature is 50-fix-dm-close-button-styling.md

---

### Session 2025-12-22 (continued)

**Feature**: 48-clickable-links-in-messages
**Status**: Completed

**What was done**:
- Added URL_REGEX constant to MessagesHelper for detecting http/https URLs
- Added linkify private helper that HTML escapes content first, then converts URLs to anchor tags
- Updated format_message to use linkify for all message types
- Links open in new tab with target="_blank" and rel="noopener noreferrer" for security
- Added CSS styling for links in messages (color: primary, underline)
- Created 12 helper tests covering URL conversion, XSS prevention, multiple URLs, etc.
- Created 5 system tests for browser verification of clickable links
- All 484 unit tests pass (2 pre-existing ISON errors unrelated)
- All 74 system tests pass
- Passed QA review

**Notes for next session**:
- The URL regex may capture trailing punctuation (acceptable per spec for IRC context)
- HTML is escaped before URL substitution to prevent XSS
- Next feature is 49-sidebar-connection-indicator-update.md

---

### Session 2025-12-22

**Feature**: 47-fix-flash-clearing-on-disconnect
**Status**: Completed

**What was done**:
- Investigated the flash clearing issue: connect clears flash but disconnect doesn't
- Found that disconnect is essentially instant (just socket close, no network handshake)
- Used AskUserQuestion to get user preference: user chose to remove the flash entirely
- Removed "Disconnecting..." flash from ConnectionsController#destroy
- Updated controller test to verify no flash on disconnect
- Updated integration test to verify no flash element rendered
- Updated system test to verify full flow (click Disconnect, no flash, indicator updates)
- All 472 unit tests pass (2 pre-existing ISON errors unrelated)
- All 69 system tests pass
- Passed QA review

**Notes for next session**:
- Connect still shows "Connecting..." flash (appropriate due to network latency)
- Disconnect has no flash (instant operation)
- Pre-existing ISON test failures need fixing (WebMock stub URL mismatch)

---

### Session 2025-12-15 (continued)

**Feature**: 44-fix-user-list-live-updates
**Status**: Completed

**What was done**:
- Investigated race condition: NAMES events triggered multiple broadcasts per user, causing some to be lost
- Added `ChannelUser.without_broadcasts` class method with thread-safe `suppress_broadcasts` flag
- Updated ChannelUser callbacks to check suppress flag before broadcasting
- Updated `IrcEventHandler#handle_names` to wrap bulk operations in `without_broadcasts` block
- Added `Channel#broadcast_user_list` public method for manual broadcast after bulk ops
- Added 2 system tests: NAMES event test (verifies all 6 users appear) and mode change test
- All 465 unit tests and 62 system tests pass
- Passed QA review

**Notes for next session**:
- Phase 11 is now complete
- All phases complete except deferred feature 33 (requires yaic LIST support)
- The `thread_mattr_accessor` ensures thread-safety for the suppress flag

---

### Session 2025-12-15 (continued)

**Feature**: 43-fix-file-uploads
**Status**: Completed

**What was done**:
- Added `has_one_attached :file` to Message model
- Added file validations: type (PNG, JPEG, GIF, WebP) and size (max 10MB)
- Added `process_file_upload` callback that generates blob URL and sends IRC PRIVMSG
- Updated MessagesController with `handle_file_upload` method for file uploads via form
- Changed message form file input name from `name="file"` to `name="message[file]"`
- UploadsController kept but no longer used by the message form (could be deleted)
- Added 5 model tests for file upload functionality
- Added 3 controller tests for file upload via MessagesController
- Updated 3 integration tests in upload_flow_test.rb to use new message-based flow
- All 465 unit tests and 60 system tests pass
- Passed QA review

**Notes for next session**:
- File processing happens in `after_create_commit` callback to ensure blob is persisted
- IRC send errors are silently caught (message still saved with file)
- The only remaining Phase 11 feature is 44-fix-user-list-live-updates.md

---

### Session 2025-12-15

**Feature**: 46-move-services-to-models
**Status**: Completed

**What was done**:
- Moved 4 files from `app/services/` to `app/models/` (internal_api_client.rb, irc_connection.rb, irc_connection_manager.rb, irc_event_handler.rb)
- Moved 4 test files from `test/services/` to `test/models/`
- Removed empty `app/services/` and `test/services/` directories
- Used `git mv` for proper tracking as renames
- All 457 unit tests and 60 system tests pass
- Passed QA review

**Notes for next session**:
- No code changes were needed, only file moves
- Rails autoloading handles both directories identically
- Remaining Phase 11 features: 43-fix-file-uploads.md, 44-fix-user-list-live-updates.md

---

### Session 2025-12-09 (continued)

**Feature**: 42-unify-userlist-partial
**Status**: Completed

**What was done**:
- Unified desktop and mobile user list into single DOM element
- User list now renders once (not duplicated in HTML)
- On desktop (≥1024px): displays as permanent right sidebar
- On mobile (<1024px): hidden off-screen, slides in as drawer when toggle clicked
- Updated `_user_list.html.erb` with drawer-header (close button, title) and content wrapper
- Removed duplicate backdrop and drawer elements from `_header.html.erb` (kept toggle button)
- Added userlist-drawer controller and backdrop to `application.html.erb` layout
- Updated `userlist_drawer_controller.js` with hasDrawerTarget guards
- Changed mobile CSS from `display: none` to `transform: translateX(100%)` for off-screen positioning
- Added drawer-header styles to `user-list.css` (hidden on desktop, visible on mobile)
- Removed obsolete `userlist-drawer.css`
- Updated 2 system test files with new selectors
- Added tests for: no duplication in HTML, live updates on mobile with drawer open
- All 457 unit tests and 60 system tests pass
- Passed QA review

**Notes for next session**:
- Phase 10 is now complete
- The key insight was using CSS transform instead of display:none for off-screen positioning
- This allows the same element to receive Turbo Stream updates in both desktop and mobile modes
- drawer-header visibility controlled by media query (hidden on desktop, flex on mobile)
- Toggle button in header uses action bubbling to reach controller on app-layout div

---

### Session 2025-12-09 (continued)

**Feature**: 41-close-dm-conversations
**Status**: Completed

**What was done**:
- Added migration for `closed_at` datetime column to conversations table
- Added `open` and `closed` scopes to Conversation model
- Added `closed?`, `close!`, and `reopen!` methods to Conversation model
- `close!` also marks conversation as read (sets last_read_message_id)
- Added `broadcast_sidebar_add` (public) and `broadcast_sidebar_remove` methods
- Created `Conversation::ClosuresController` with `create` action (follows Rails 7-actions convention)
- Added route `resource :closure, only: [:create]` nested under conversations
- Updated `ConversationsController#create` to reopen closed conversations when initiating DM
- Updated sidebar to only show open conversations (`server.conversations.open`)
- Added close button (X) to conversation sidebar item, visible on hover
- Updated `IrcEventHandler#handle_message` to reopen closed conversations on new message
- Added 8 model tests for close/reopen functionality
- Added 3 controller tests for Conversation::ClosuresController
- Added 1 test for reopening in ConversationsController
- Added 5 integration tests for broadcasts and reopen behavior
- Added 4 system tests for close button hover, clicking close, reopen on message, clicking username
- All 457 unit tests and 58 system tests pass
- Passed QA review (after refactoring to follow Rails conventions)

**Notes for next session**:
- Close button uses CSS `opacity: 0` by default, `opacity: 1` on hover
- Closing a DM redirects to the server page
- Auto-reopen broadcasts sidebar add so the DM reappears in real-time
- Next feature is 42-unify-userlist-partial.md

---

### Session 2025-12-09 (continued)

**Feature**: 40-dm-user-online-status
**Status**: Completed

**What was done**:
- Added `target_online?` method to Conversation model that delegates to `server.nick_online?(target_nick)`
- Added `has_many :channel_users, through: :channels` association to Server model
- Added `nick_online?(nickname)` method to Server model with case-insensitive SQL query
- Added `broadcast_presence_update` method to Conversation model as public wrapper for sidebar updates
- Added `after_create_commit :notify_dm_presence` and `after_destroy_commit :notify_dm_presence` callbacks to ChannelUser model
- `notify_dm_presence` method finds matching DM conversations (case-insensitive) and triggers sidebar updates
- Updated `_conversation_sidebar_item.html.erb` with presence indicator span using `-online`/`-offline` classes
- Added CSS for presence indicator in `dm-item.css` (8px green/gray dot)
- Added 3 model tests for `target_online?`, 3 tests for `nick_online?`, 4 tests for ChannelUser callbacks
- Added 4 system tests (2 for initial display state, 2 for live updates via broadcast)
- All 440 unit tests and 54 system tests pass
- Passed QA review

**Notes for next session**:
- System tests for live updates call `conversation.broadcast_presence_update` explicitly after IrcEventHandler triggers
- This is due to how Rails transactional tests interact with ActionCable in system tests
- Model tests use `assert_turbo_stream_broadcasts` to verify callback triggers broadcasts correctly
- The presence indicator uses `var(--color-success)` for online (green) and `var(--color-gray-400)` for offline
- Next feature is 41-close-dm-conversations.md

---

### Session 2025-12-09

**Feature**: 39-unify-dm-channel-views
**Status**: Completed

**What was done**:
- Added `display_name` and `subtitle` methods to Channel model (returns name and topic)
- Added `display_name` and `subtitle` methods to Conversation model (returns target_nick and "Direct Message")
- Refactored `channels/_header.html.erb` to accept polymorphic `messageable` local variable
- Refactored `channels/_input.html.erb` to accept `messageable` local variable
- Refactored `messages/_form.html.erb` to handle both Channel and Conversation contexts
- Updated `conversations/show.html.erb` to use the shared partials from channels/
- Updated `channels/show.html.erb` to pass `messageable:` instead of `channel:` to partials
- Updated Channel model `broadcast_joined_status` to pass `messageable:` in locals
- Added 2 model tests for Channel#display_name and Channel#subtitle
- Added 2 model tests for Conversation#display_name and Conversation#subtitle
- Added 3 system tests (DM view renders correctly, channel view still works, DM message sending works)
- Updated dm_initiation_test.rb selectors to match new structure (.header .name instead of .channel-header h1)
- All tests pass (430 unit tests, 50 system tests)
- Passed QA review

**Notes for next session**:
- Header partial uses `is_channel = messageable.is_a?(Channel)` for conditional logic
- For DMs: no userlist-toggle, no auto-join form, no leave button
- For channels: all existing functionality preserved
- Next feature is 40-dm-user-online-status.md

---

### Session 2025-12-02 (continued)

**Feature**: 38-dm-initiation
**Status**: Completed

**What was done**:
- Fixed /msg command to create Conversation record in MessagesController#send_pm
- Added conversations#create action that finds or creates conversation and redirects to it
- Added route for conversations nested under servers (resources :conversations, only: [:create])
- Made usernames clickable in user list (_user_list_content.html.erb) using link_to with turbo_method: :post
- Made usernames clickable in messages (_message.html.erb) using link_to with turbo_method: :post
- Added CSS styles for username links in user-list.css and message-item.css
- Added 4 controller tests for conversations#create (create, redirect, find existing, access control)
- Added 3 controller tests for /msg creating conversation (creates, updates last_message_at, finds existing)
- Added 3 system tests for DM initiation (click user list, creates sidebar entry, click message)
- Added 1 integration test for /msg then view conversation flow
- All tests pass (426 unit tests, 47 system tests)
- Passed QA review

**Notes for next session**:
- Phase 9 is now complete
- The @created_conversation instance variable is set but not used for redirect (spec mentions optional Turbo visit approach)
- Username links use POST method via data-turbo-method attribute

---

### Session 2025-12-02 (continued)

**Feature**: 37-mobile-userlist-drawer
**Status**: Completed

**What was done**:
- Created userlist_drawer_controller.js Stimulus controller for open/close with global keydown handler
- Extracted user list content into _user_list_content.html.erb partial
- Updated _user_list.html.erb to use the content partial
- Added toggle button and slide-in drawer to channel header partial
- Created 3 RSCSS-compliant CSS files: userlist-toggle.css, userlist-backdrop.css, userlist-drawer.css
- Toggle button shows user count (&#128101; icon), visible only on viewports < 1024px
- Drawer slides in from right, width 240px on tablet, 100% on phone (< 768px)
- Close via X button, backdrop click, or Escape key
- Body overflow hidden when drawer open to prevent scroll
- Added 7 system tests covering toggle visibility, open/close interactions
- All tests pass (418 unit tests, 44 system tests)
- Passed QA review

**Notes for next session**:
- Stimulus controller uses global keydown event listener added on open, removed on close
- CSS properly split into 3 component files per RSCSS conventions
- Element classes are single words: header, title, close, content
- Next feature is 38-dm-initiation.md

---

### Session 2025-12-02 (continued)

**Feature**: 36-fix-server-page-layout
**Status**: Completed

**What was done**:
- Fixed CSS specificity issue in app-layout.css where `-no-userlist` variant overrode media query
- Changed `@media (max-width: 1023px) { grid-template-columns: 1fr; }` to include `-no-userlist` in selector
- Added 4 system tests for mobile/tablet/desktop layouts on server and channel pages
- All tests pass (418 unit tests, 37 system tests)
- Passed QA review

**Notes for next session**:
- The fix uses `&, &.-no-userlist { grid-template-columns: 1fr; }` inside the media query
- This ensures the mobile rule matches or exceeds the specificity of the `-no-userlist` variant
- Tests verify main content width is > 90% of viewport on mobile/tablet

---

### Session 2025-12-02 (continued)

**Feature**: 35-fix-sidebar-live-updates
**Status**: Completed

**What was done**:
- Fixed Message#broadcast_sidebar_update stream name from `user_#{id}_sidebar` to `sidebar_#{id}`
- Added Channel#broadcast_sidebar_joined_status callback for real-time sidebar updates on join/leave
- Added Conversation broadcasts (after_create_commit and after_update_commit for last_message_at)
- Updated sidebar view with target IDs for channels and DMs lists (wrapped in section divs)
- Added CSS `:has()` selectors to hide empty DM and Channels sections
- Added model tests for all broadcast behaviors
- Added 4 system tests covering DM creation, channel join, channel leave, unread count updates
- Fixed test for PM flow to match new sidebar structure (sections always rendered, hidden via CSS)
- All tests pass (418 unit tests, 33 system tests)
- Passed QA review

**Notes for next session**:
- Message broadcast uses `Current.user_id || Current.user&.id` to support both internal API and web contexts
- Sidebar sections use CSS `:has(.list:empty)` to hide when no items, so Turbo Streams always have a target to append to
- The `unread_count` method returns 0 when `last_read_message_id` is nil - this is intentional per existing behavior

---

### Session 2025-12-02 (continued)

**Feature**: 34-fix-message-auto-scroll
**Status**: Completed

**What was done**:
- Fixed channel view: added `data-message-list-target="messages"` and `data-message-list-target="container"` attributes
- Updated MutationObserver to watch the inner container target instead of the outer messages div
- Added `sent()` method to message-list controller for scroll-on-send behavior
- Wired up message form to call message-list#sent via Stimulus outlet
- Applied same fixes to conversation view for PM auto-scroll
- Created RSCSS-compliant new-messages-indicator.css component with `-hidden` variant
- Added 4 system tests covering all spec scenarios (auto-scroll at bottom, no scroll when reading history, click indicator to scroll, scroll on send)
- All tests pass (413 unit tests, 29 system tests)
- Passed QA review

**Notes for next session**:
- The indicator uses `-hidden` variant class following RSCSS conventions
- MutationObserver watches `containerTarget` (inner `#messages` div where Turbo appends)
- Message form uses Stimulus outlet to communicate with message-list controller
- Tests resize browser to 600px height to ensure scrollable content

---

### Session 2025-12-02 (continued)

**Feature**: 31-verify-user-list-live-updates
**Status**: Re-completed

**What was done**:
- Fixed ChannelUser model: added explicit `Turbo::Broadcastable` include
- Fixed callback merging issue by using separate method names for after_create_commit, after_destroy_commit, after_update_commit
- Added guard in after_destroy_commit to skip broadcast if channel was already deleted (dependent: :destroy case)
- Added 4 broadcast tests to ChannelUser model (create, destroy, mode change, no-broadcast-on-unrelated-update)
- Created system test file with 5 tests (join, part, quit, kick, multiple sequential events)
- Fixed critical bug: user list partial missing target ID causing subsequent Turbo Stream updates to fail
- All tests pass (413 unit tests, 25 system tests)
- Passed QA review

**Notes for next session**:
- The user list partial now has the target ID directly in it (`channel_<%= channel.id %>_user_list`)
- Removed duplicate wrapper div from channels/show.html.erb
- The multiple sequential events test verifies join->join->part->kick all work in sequence

---

### Session 2025-12-02 (continued)

**Feature**: 36-nick-change-live-update
**Status**: Completed

**What was done**:
- Verified existing `broadcast_nickname_change` callback in Server model works correctly
- Added 2 model tests for nickname broadcast behavior (broadcasts on change, no broadcast when unchanged)
- Added 1 integration test for Turbo Stream broadcast via IrcEventHandler
- Added 1 system test verifying real-time nickname update in browser
- All tests pass (409 unit tests, 20 system tests)
- Passed QA review

**Notes for next session**:
- All Phase 8 features are complete (except deferred #33 which requires yaic LIST support)
- The nickname is only displayed on the server show page
- Sidebar shows server address, header shows user email (neither shows IRC nickname)
- Existing broadcast implementation was already correct, just needed test coverage

---

### Session 2025-12-02 (continued)

**Feature**: 34-connection-timeouts
**Status**: Completed

**What was done**:
- Verified existing timeout handling in IrcConnection works correctly
- When yaic raises TimeoutError, it's caught and sends "error" + "disconnected" events
- Added unit test for connect timeout triggering error and disconnect events
- Added integration test for full timeout flow marking server disconnected
- All tests pass (406 unit tests, 19 system tests)
- Passed QA review

**Notes for next session**:
- yaic already handles timeouts via Yaic::TimeoutError
- No code changes needed - this was verification + tests
- Only feature 36 remains in Phase 8

---

### Session 2025-12-02 (continued)

**Feature**: 35-fix-kick-message-format
**Status**: Completed

**What was done**:
- Fixed IrcEventHandler#handle_kick to store kicked user as sender (instead of kicker)
- Changed content format to "was kicked by {kicker} ({reason})"
- Updated format_message helper to concatenate sender + content for kick messages
- Added test for empty/nil reason handling
- Added integration test for kick message display
- All tests pass (404 unit tests, 19 system tests)
- Passed QA review

**Notes for next session**:
- Kick messages now display as "{kicked_nick} was kicked by {kicker} ({reason})"
- Empty reasons result in no parentheses: "{kicked_nick} was kicked by {kicker}"

---

### Session 2025-12-02 (continued)

**Feature**: 33-list-public-channels
**Status**: Deferred

**What was done**:
- Checked yaic gem for LIST command support
- Found yaic missing handlers for 322 (RPL_LIST) and 323 (RPL_LISTEND) numerics
- No :list event type defined in yaic
- Deferred feature until yaic is updated with LIST support

**Notes for next session**:
- Feature requires yaic changes before implementation
- Pick from features 34, 35, or 36 next

---

### Session 2025-12-02 (continued)

**Feature**: 32-channel-name-links-to-show
**Status**: Completed

**What was done**:
- Changed channel name from `<span>` to `<%= link_to %>` in servers/_channels.html.erb
- Added 2 integration tests for link presence (joined and not-joined states)
- Added 1 system test for click navigation behavior
- All tests pass (402 unit tests, 19 system tests)
- Passed QA review

**Notes for next session**:
- Simple UI change - channel name is now a clickable link to channel show page
- The "View" button is still present for joined channels (link on name is additional)

---

### Session 2025-12-02 (continued)

**Feature**: 31-verify-user-list-live-updates
**Status**: Completed

**What was done**:
- Investigated reported issue of user list not updating live
- Verified yaic correctly emits join/part/quit events for all users (not just self)
- Verified IrcConnection correctly forwards events via `@on_event.call`
- Verified IrcEventHandler correctly creates/destroys ChannelUser records
- Verified ChannelUser model has correct Turbo Stream broadcast callbacks
- Verified channel view correctly subscribes to `@channel, :users` stream
- Conclusion: Implementation is correct, no bug found
- Added missing test for quit event updating user list across all channels

**Notes for next session**:
- The user list live update feature was already fully implemented and working
- Turbo Stream broadcasts go to `[channel, :users]` stream with target `channel_#{id}_user_list`
- Feature 36 (nick change live update) may now be simpler since broadcasts are verified working

---

### Session 2025-11-29

**Feature**: 01-auth-signin
**Status**: Completed

**What was done**:
- Created User model with has_secure_password and email normalization
- Created Session model with belongs_to user association
- Implemented SessionsController for login/logout flows
- Implemented PasswordsController for password reset flows
- Created PasswordsMailer for reset emails
- Added Authentication concern for session management
- Created views for login, password reset request, and password reset
- Added rate limiting (10 requests per 3 minutes) on login and password reset
- Implemented email enumeration protection (same response for valid/invalid emails)
- Added comprehensive test coverage for all controllers
- Passed QA review

**Notes for next session**:
- bin/brakeman had --ensure-latest flag that caused CI failures; removed it
- Authentication uses Rails' signed tokens for password reset with expiration

---

### Session 2025-11-29 (continued)

**Feature**: 02-auth-multitenant
**Status**: Completed

**What was done**:
- Added activerecord-tenanted gem from Basecamp
- Configured database.yml with tenant database at storage/tenants/{env}/{user_id}/main.sqlite3
- Created TenantRecord base class for tenant models
- Created Server model in tenant database with validation
- Added after_create callback to User model to create tenant database
- Configured tenant resolver to use session user_id for automatic tenant switching
- Created Tenant.switch(user) convenience method as documented in spec
- Added unit tests for tenant isolation (User A cannot see User B's servers)
- Added integration test for web request scoping
- Created ServersController with views for testing

**Notes for next session**:
- activerecord-tenanted gem handles tenant switching via middleware automatically
- TenantRecord.with_tenant(tenant_id) for explicit tenant switching
- Tenant.switch(user) is a convenience wrapper
- Fixture users need tenant databases created in test setup

---

### Session 2025-11-29 (continued)

**Feature**: 03-server-crud
**Status**: Completed

**What was done**:
- Completed Server model with all validations (address, port, nickname format, auth_method, auth_password)
- Added encrypted auth_password using Rails ActiveRecord encryption
- Implemented defaults via before_validation (port: 6697, ssl: true, auth_method: none, username/realname default to nickname)
- Added uniqueness constraint on address+port per tenant
- Completed ServersController with all 7 RESTful actions
- Created form partial with all fields (address, port, ssl, nickname, username, realname, auth_method, auth_password)
- Added Stimulus controller for conditional auth_password visibility
- Created show page with server details and channels placeholder
- Created edit page using shared form partial
- Updated index to show connection status and link to server
- Updated routes to set root path to servers#index
- Added comprehensive model tests (15 tests)
- Added controller tests (24 tests)
- Added integration tests (3 tests)
- Passed QA review

**Notes for next session**:
- ActiveRecord encryption requires keys in credentials file (active_record_encryption.primary_key, deterministic_key, key_derivation_salt)
- Channels section on show page is a placeholder until channels feature is implemented
- auth_method_controller.js handles showing/hiding password field based on auth method selection

---

### Session 2025-11-30

**Feature**: 04-internal-api
**Status**: Completed

**What was done**:
- Created Internal::BaseController as common base for internal API controllers
- Implemented InternalApiAuthentication concern with Bearer token auth using secure_compare
- Added user_id attribute to Current for use in model callbacks
- Created ConnectionsController for starting/stopping IRC connections
- Created CommandsController for sending IRC commands
- Created StatusController for health checks and connection listing
- Created EventsController for receiving IRC events with tenant switching
- Created InternalApiClient service using Net::HTTP for HTTP communication
- Created IrcConnectionManager stub (singleton, thread-safe with mutex)
- Created IrcEventHandler stub (handles connected/disconnected events)
- Added routes namespaced under /internal/irc/
- Added service URL configs to all environment files
- Added webmock gem for HTTP stubbing in tests
- Added comprehensive controller tests (13 tests)
- Added InternalApiClient unit tests (8 tests)
- Passed QA review

**Notes for next session**:
- Internal API uses Bearer token from INTERNAL_API_SECRET env var
- Controllers inherit from Internal::BaseController (not ApplicationController) for clean separation
- IrcConnectionManager and IrcEventHandler are stubs - will be fully implemented in later features
- Use PARALLEL_WORKERS=1 when running tests in sandbox mode (DRB socket issue)

---

### Session 2025-11-30 (continued)

**Feature**: 05-irc-connections
**Status**: Completed

**What was done**:
- Added yaic gem for IRC client library
- Implemented IrcConnection wrapper around yaic with thread management
- Implemented IrcConnectionManager singleton with start/stop/send_command/connected?
- Added user-facing ConnectionsController for connect/disconnect via internal API
- Added routes for `resource :connection` nested under servers
- Created production setup with bin/irc_service and config/puma/irc_service.rb
- Added unit tests for IrcConnectionManager (9 tests)
- Added unit tests for IrcConnection (5 tests)
- Added controller tests for ConnectionsController (4 tests)
- Added integration tests for connect/disconnect flow (2 tests)
- Updated internal API tests to mock IrcConnection
- Added ENV["INTERNAL_API_SECRET"] to test_helper.rb
- Passed QA review

**Notes for next session**:
- IrcConnection exposes `running?` and `alive?` public methods for testability
- Tests use mock classes instead of instance_variable_get (per conventions)
- yaic gem is referenced via path: "~/workspace/yaic" in Gemfile
- IrcConnectionManager.instance.reset! cleans up connections for test isolation

---

### Session 2025-11-30 (continued)

**Feature**: 06-channels
**Status**: Completed

**What was done**:
- Created Channel model with validations (name presence, format #/&, uniqueness per server)
- Created ChannelUser model with validations (nickname presence, uniqueness per channel)
- Implemented Channel methods: unread_count, has_unread?, mark_as_read
- Implemented ChannelUser methods: op?, voiced?, and scopes (ops, voiced, regular)
- Created ChannelsController with show, create, destroy actions
- Added routes: nested create under servers, standalone show/destroy
- Updated server show view with channel list and join form (only when connected)
- Updated IrcEventHandler to handle join/part events
- Created Message model placeholder for channel messages association
- Added flash message display to application layout
- Added Channel model tests (15 tests)
- Added ChannelUser model tests (14 tests)
- Added ChannelsController tests (16 tests)
- Added integration tests for join/leave flows (4 tests)
- Passed QA review

**Notes for next session**:
- Message model is a placeholder - will be expanded in 07-messages-receive
- Channel validation regex uses /\A[#&].+\z/ (stricter than spec, requires at least one char after #/&)
- IrcEventHandler now handles join/part events to update channel.joined status
- WebMock.reset! used in tests to override setup stubs for error case tests

---

### Session 2025-11-30 (continued)

**Feature**: 07-messages-receive
**Status**: Completed

**What was done**:
- Implemented IrcEventHandler for all event types (message, action, notice, join, part, quit, kick, nick, topic, names, connected, disconnected)
- Updated Message model with server/channel associations, sender field, message_type, and Turbo broadcasts
- Created Notification model for DMs and highlights (validates reason: dm or highlight)
- Added highlight detection (case-insensitive nickname matching in message content)
- Created _message partial for Turbo Stream broadcasts
- MAJOR CHANGE: Removed activerecord-tenanted gem entirely
- Migrated from separate tenant databases to standard Rails associations
- Server now belongs_to :user for data isolation
- Updated all models, controllers, and tests for new architecture
- Updated all documentation (data-model.md, feature specs) for new architecture
- Added IrcEventHandler tests (19 tests)
- Added Message model tests (9 tests)
- Added EventsController tests (11 tests)
- Passed QA review

**Notes for next session**:
- No more TenantRecord - all models inherit from ApplicationRecord
- Data isolation via user -> servers -> channels -> messages associations
- Controllers use current_user.servers.find(id) for scoped queries
- IrcEventHandler.handle(server, event) is the main entry point

---

### Session 2025-11-30 (continued)

**Feature**: 08-messages-send
**Status**: Completed

**What was done**:
- Created MessagesController with create action for sending messages
- Implemented all IRC commands: /me, /msg, /notice, /nick, /topic, /part
- Added from_me? method to Message model (case-insensitive nickname matching)
- Added connected? helper method to Server model
- Updated channel show view with Turbo Stream subscription and message input form
- Added routes for messages nested under both channels and servers
- Created create.turbo_stream.erb to clear input field after send
- Added controller tests (16 tests)
- Added integration tests (3 tests)
- Added model tests for from_me? (3 tests)
- Passed QA review

**Notes for next session**:
- Don't name methods `send_action` - it conflicts with Rails' ActionController method
- Messages are created locally before sending to IRC (optimistic UI)
- Turbo Stream broadcasts are handled by the Message model after_create_commit callback
- Use Current.user (not current_user) to access the authenticated user

---

### Session 2025-11-30 (continued)

**Feature**: 09-messages-history
**Status**: Completed

**What was done**:
- Updated ChannelsController#show to load all messages ordered by created_at
- Updated channel show view to display messages with timestamps
- Added timestamp display to message partial (time for today, date+time otherwise)
- Created Stimulus message-list controller for scroll-to-bottom behavior
- Added new-messages indicator (hidden by default, shown when scrolled up)
- Added controller tests for message loading and ordering
- Added integration tests for message history display
- Simplified implementation per user request: loads all messages, no pagination/infinite scroll

**Notes for next session**:
- Pagination/infinite scroll deferred to later - user requested simplicity
- System tests not set up yet - JS behavior tests (like new message indicator) would need those
- Date separators between days not implemented - could add later
- CSS for message list, timestamps, and new-messages indicator not styled yet

---

### Session 2025-11-30 (continued)

**Feature**: 11-notifications-unread
**Status**: Completed

**What was done**:
- Renamed Channel#has_unread? to Channel#unread? for consistency with spec
- Renamed Channel#mark_as_read to Channel#mark_as_read! (uses update!)
- Added unread? logic to handle nil last_read_message_id (all messages unread)
- Updated ChannelsController#show to call mark_as_read! when viewing channel
- Added broadcast_sidebar_update to Message model for real-time sidebar updates
- Created shared/_channel_sidebar_item.html.erb partial for Turbo Stream broadcasts
- Fixed servers/show.html.erb to use unread? instead of has_unread?
- Added model tests for unread_count, unread?, mark_as_read!
- Added controller tests for marking channel as read
- Added integration tests for unread indicators
- Passed QA review

**Notes for next session**:
- Sidebar broadcasts use Current.user_id to target the correct user's sidebar
- The sidebar partial uses RSCSS-compliant class names (channel-item, -unread, badge)
- unread_count returns 0 when last_read_message_id is nil (per spec decision to mark as read on join)

---

### Session 2025-11-30 (continued)

**Feature**: 13-ui-layout
**Status**: Completed

**What was done**:
- Created CSS variables file with design tokens (colors, spacing, typography)
- Created RSCSS-compliant CSS components: app-layout, app-header, channel-sidebar, channel-item, connection-indicator
- Updated application layout with CSS Grid (header, sidebar, main, optional userlist)
- Created shared/_header partial with logo, notifications, and user menu
- Created shared/_sidebar partial showing servers grouped with channels
- Added ApplicationHelper methods: current_user_servers, current_channel, unread_notification_count
- Created sidebar Stimulus controller for mobile hamburger menu toggle
- Added responsive behavior (sidebar hides on tablet/mobile with hamburger toggle)
- Added integration tests for sidebar display (7 tests)
- Added system tests for layout structure and navigation (6 tests)
- Passed QA review

**Notes for next session**:
- unread_notification_count returns 0 (placeholder until 12-notifications-highlights implements it)
- System tests use Cuprite driver with Capybara
- Each CSS component is in its own file per RSCSS conventions
- content_for?(:userlist) controls whether user list column is shown

---

### Session 2025-11-30 (continued)

**Feature**: 10-pm-view
**Status**: Completed

**What was done**:
- Created Conversation model with migration (target_nick, last_read_message_id, last_message_at)
- Added validations for target_nick presence and uniqueness per server
- Implemented messages method to return PM messages for conversation (both sent and received)
- Implemented unread_count, unread?, mark_as_read! methods
- Updated IrcEventHandler to create/update Conversation when PM is received
- Created ConversationsController with show action
- Created Conversation::MessagesController for sending PMs
- Added routes for conversations with nested messages
- Updated sidebar to show DMs section above Channels section
- Created conversation_sidebar_item partial with unread badges
- Created conversation show view (reuses channel-view styling)
- Added CSS for dm-item and section-label components
- Added model tests (14 tests)
- Added controller tests (14 tests)
- Added integration tests (12 tests)
- Passed QA review

**Notes for next session**:
- Conversation.messages uses OR query for both sent/received messages
- DMs are sorted by last_message_at desc in sidebar
- unread? method correctly handles nil last_read_message_id (new conversations)
- Broadcast sidebar updates for new PM messages not implemented (could be added later)

---

### Session 2025-11-30 (continued)

**Feature**: 12-notifications-highlights
**Status**: Completed

**What was done**:
- Added read_at column to notifications table
- Updated Notification model with unread/recent scopes, read? and mark_as_read! methods
- Updated IrcEventHandler with word boundary matching for highlights (/\b#{nickname}\b/i)
- Added check to skip highlights from self
- Created NotificationsController with index and update actions
- Added routes for notifications (index, update only - RESTful)
- Created notification list view and _notification partial
- Created CSS components: notification-list.css, notification-item.css
- Updated ApplicationHelper#unread_notification_count to query actual count
- Created notifications_controller.js Stimulus controller for browser push notifications
- Created NotificationsChannel for ActionCable broadcasts
- Created ApplicationCable::Channel base class
- Updated header partial to link bell to notifications page
- Added ActionCable pin to importmap.rb
- Added model tests (12 tests)
- Added controller tests (13 tests)
- Added integration tests (10 tests)
- Passed QA review

**Notes for next session**:
- Browser notifications use MVP approach (Notification API when tab is open)
- ActionCable broadcasts happen from IrcEventHandler on notification creation
- Word boundary matching prevents partial matches (e.g., "joey" doesn't match "joe")
- NotificationsController scopes notifications through message->server->user associations

---

### Session 2025-11-30 (continued)

**Feature**: 14-ui-server-view
**Status**: Completed

**What was done**:
- Updated ServersController#show to load channels (joined, with channel_users eager loaded) and server messages
- Created new server view layout with RSCSS-compliant CSS structure
- Server header shows address:port, SSL badge, nickname, connection status and "since" timestamp
- Actions section with Connect/Disconnect, Edit, Delete buttons
- Join Channel section (only visible when connected)
- Channels section with list showing name, user count, View and Leave links
- Server Messages collapsible section with details/summary
- Created server-view.css component following RSCSS conventions (all styles nested under .server-view)
- Added N+1 prevention with includes(:channel_users) and using .size
- Added controller tests (6 new tests)
- Added integration tests (4 tests in server_page_test.rb)
- Passed QA review

**Notes for next session**:
- All elements in server-view.css use single-word element names nested under .server-view component
- .button, .link, .badge, .empty are styled as elements within the component using `& .button` syntax
- Uses .size instead of .count for channel_users to use the eager-loaded association

---

### Session 2025-11-30 (continued)

**Feature**: 15-ui-channel-view
**Status**: Completed

**What was done**:
- Created RSCSS-compliant CSS components: channel-view.css, message-item.css, message-input.css, user-list.css
- Updated channels/show.html.erb with new layout structure and content_for :userlist
- Updated messages/_message.html.erb partial with RSCSS classes and format_message helper
- Created messages/_form.html.erb partial for message input form
- Created channels/_user_list.html.erb partial for user list sidebar
- Created MessagesHelper with format_message and current_nickname methods
- Added highlight? method to Message model for nickname mention detection
- Created message_form_controller.js Stimulus controller for Enter key submission
- Added system tests for channel view (7 tests)
- Added unit tests for highlight? method (10 tests)
- Updated existing tests to use new CSS class names (.message-item instead of .message, etc.)
- Passed QA review

**Notes for next session**:
- Message types have different styling via CSS variants (-privmsg, -action, -notice, -join, -part, -quit, -kick, -topic, -nick)
- Own messages get -mine class, highlighted messages get -highlight class
- User list groups users by mode (ops with @, voiced with +, regular)
- CSS ::before pseudo-elements add the @ and + prefixes, not the HTML

---

### Session 2025-11-30 (continued)

**Feature**: 16-media-upload
**Status**: Completed

**What was done**:
- Created UploadsController with create action for file uploads
- Implemented file type validation (PNG, JPEG, GIF, WebP only)
- Implemented file size validation (max 10MB)
- Files uploaded to ActiveStorage using Blob.create_and_upload!
- URL generated for uploaded file via rails_blob_url
- Message record created with URL as content
- IRC command sent to channel with the URL
- Added routes for uploads nested under channels
- Updated message form with upload button (📎)
- Updated message_form_controller.js Stimulus controller with upload handler
- Added CSS for upload button in message-input.css
- Created test fixture files (test.png, test.jpg, test.gif, test.webp, test.pdf)
- Added ActiveStorage migration (create_active_storage_tables)
- Added controller tests (11 tests)
- Added integration tests (3 tests)
- Passed QA review

**Notes for next session**:
- All planned features have been implemented!
- ActiveStorage uses :local service in development, :test service in test
- Upload URLs use rails_blob_url which redirects to the actual storage location
- The JavaScript upload handler uses fetch() with FormData for file uploads
- Error responses use JSON format (error message in json["error"])

---

### Session 2025-11-30 (continued)

**Feature**: 17-fix-user-list
**Status**: Completed

**What was done**:
- Fixed data key mismatch in `serialize_names_event` - changed `users:` to `names:` to match `handle_names` expectation
- Added Turbo Stream broadcasts to ChannelUser model for real-time user list updates
- Added `after_create_commit`, `after_destroy_commit`, and `after_update_commit` (for mode changes) callbacks
- Added stream subscription in channel view (`turbo_stream_from @channel, :users`)
- Wrapped user list partial with target ID for Turbo Stream replacement
- Added unit test "handle_names clears existing users first"
- Added integration tests for user count display, names event, join/part events
- Passed QA review

**Notes for next session**:
- ChannelUser broadcasts to `[channel, :users]` stream
- The target ID is `channel_#{channel.id}_user_list`
- Mode changes also trigger user list updates (for user moving between op/voiced/regular groups)

---

### Session 2025-11-30 (continued)

**Feature**: 18-fix-channels-list
**Status**: Completed

**What was done**:
- Fixed data key mismatch in IrcConnection serializers to match IrcEventHandler expectations
- `serialize_join_event`: Changed `channel:` to `target:`
- `serialize_part_event`: Changed `channel:` to `target:`, `reason:` to `text:`
- `serialize_quit_event`: Changed `reason:` to `text:`
- `serialize_topic_event`: Changed `channel:` to `target:`, `topic:` to `text:`, added `source:` from `setter`
- `serialize_nick_event`: Changed to use `source:` for old_nick (works with source_nick method)
- `serialize_kick_event`: Changed `channel:` to `target:`, `reason:` to `text:`, `by:` to `source:`
- Added 3 integration tests for channel list display on server pages
- Passed QA review

**Notes for next session**:
- IrcConnection serializers now use consistent keys: `source:`, `target:`, `text:` (matching message events)
- The `serialize_names_event` uses `channel:` which is correct since `handle_names` expects `data[:channel]`
- Same pattern as 17-fix-user-list - mismatch between serializer output and handler expectations

---

### Session 2025-12-01

**Feature**: 19-ssl-no-verify
**Status**: Completed

**What was done**:
- Added migration for ssl_verify boolean column with default true
- Updated Server model to set ssl_verify default in set_defaults method
- Updated ServersController to permit :ssl_verify param
- Updated server form with ssl_verify checkbox and Stimulus controller for toggle
- Created ssl_controller.js to show/hide ssl_verify checkbox based on SSL checkbox state
- Updated ConnectionsController to pass ssl_verify in config to InternalApiClient
- Updated IrcConnection to pass verify_ssl to Yaic::Client
- Added model tests (ssl_verify defaults to true, ssl_verify can be set to false)
- Added controller tests (create/update with ssl_verify)
- Added integration tests (form shows option, checkbox checked by default)
- Added system tests for JS toggle behavior (visible/hidden/re-appears)
- Passed QA review

**Notes for next session**:
- The yaic gem supports verify_ssl parameter (Yaic::Client.new(..., verify_ssl: false))
- System tests need to wait for login to complete before navigating (assert_no_selector for password field)

---

### Session 2025-12-01 (continued)

**Feature**: 20-nick-change-sync
**Status**: Completed

**What was done**:
- Updated IrcEventHandler#handle_nick to sync Server.nickname when own nick changes
- Added case-insensitive comparison using `casecmp?` method
- Added Turbo Stream broadcast for real-time UI updates when nickname changes
- Added `after_update_commit :broadcast_nickname_change` callback to Server model
- Added `turbo_stream_from @server` subscription in server show view
- Added target ID on nickname element for Turbo Stream replacement
- Added 4 unit tests for nick sync functionality
- Added 2 integration tests for nick change UI updates
- Passed QA review

**Notes for next session**:
- All planned features are now complete
- Server model broadcasts nickname changes directly using html: parameter (simple inline HTML)
- Turbo::Broadcastable is included explicitly in Server model for clarity

---

### Session 2025-12-01 (continued)

**Feature**: 21-realtime-connection-status
**Status**: Completed

**What was done**:
- Added `after_update_commit :broadcast_connection_status, if: :saved_change_to_connected_at?` callback to Server model
- Created three partials for Turbo Stream broadcasts: `_status.html.erb`, `_actions.html.erb`, `_join.html.erb`
- Each partial has a target ID using `dom_id(server, :status/actions/join)` for Turbo Stream replacement
- Updated server show view to use the new partials
- Added Turbo::Broadcastable::TestHelper to test_helper.rb for broadcast assertion support
- Added 3 model tests for broadcast behavior (connect, disconnect, unchanged)
- Added 2 integration tests for server page updates via IrcEventHandler
- Passed QA review

**Notes for next session**:
- The server show view already had `turbo_stream_from @server` subscription
- Partials use `dom_id(server, :prefix)` helper for consistent target IDs
- The `broadcast_replace_to` method broadcasts to `self` (server) stream with partials

---

### Session 2025-12-01 (continued)

**Feature**: 22-channel-join-prefix
**Status**: Completed

**What was done**:
- Added `normalize_channel_name` private method to ChannelsController
- Method strips leading/trailing whitespace and prepends `#` if name doesn't start with `#` or `&`
- Updated `create` action to call `normalize_channel_name` before `find_or_initialize_by`
- Added 5 controller tests covering all spec test cases
- Added 1 integration test for user flow
- Passed QA review

**Notes for next session**:
- The normalization happens in the controller (not model) to keep validation strict
- `&` prefix is preserved for IRC local channels

---

### Session 2025-12-01 (continued)

**Feature**: 23-channel-joined-state-reset
**Status**: Completed

**What was done**:
- Updated `IrcEventHandler#handle_disconnected` to reset all channel joined status and clear all channel_users
- Added `@server.channels.update_all(joined: false)` to reset joined status
- Added `ChannelUser.joins(:channel).where(channels: { server_id: @server.id }).delete_all` to clear users
- Updated channel view to show "not in this channel" banner when not joined
- Updated channel view to show "Join" button instead of "Leave" when not joined
- Updated message form to show disabled input when connected but not joined
- Updated server view to show all channels (not just joined ones)
- Added different styling and actions for not-joined channels on server page (italic, grayed out, Join/Remove buttons)
- Updated ServersController to load all channels instead of just joined ones
- Added CSS for not-joined-banner and not-joined channel row styling
- Added 2 unit tests for handle_disconnected
- Added 4 controller tests for channel show when not joined
- Added 3 integration tests for disconnect flow
- Added 1 system test for disabled channel input
- Passed QA review

**Notes for next session**:
- Server page now shows all channels, not just joined ones
- Not-joined channels have `-not-joined` CSS variant class for styling
- Message input is disabled when connected but not joined (shows placeholder text field)
- When server disconnects, it also becomes not connected, so message form shows "Connect to server to send messages" message

---

### Session 2025-12-01 (continued)

**Feature**: 24-auto-join-channels
**Status**: Completed

**What was done**:
- Added migration for auto_join boolean column with default false
- Updated IrcEventHandler#handle_connected to call auto_join_channels method
- Added auto_join_channels method that queries channels with auto_join: true and sends JOIN commands
- Added proper error handling (rescues ServiceUnavailable and ConnectionNotFound, logs errors)
- Added update action to ChannelsController for toggling auto_join
- Added auto_join to channel_params permitted attributes
- Added update route for channels
- Updated server view with auto-join badge and checkbox toggle for each channel
- Updated channel view header with auto-join badge and toggle label
- Added CSS for auto-join-badge and auto-join-form styling
- Added 2 model tests for auto_join defaults and updates
- Added 4 unit tests for IrcEventHandler auto-join behavior
- Added 2 controller tests for PATCH auto_join update
- Added 5 integration tests for complete auto-join flow
- Passed QA review

**Notes for next session**:
- Auto-join happens after connected_at is updated in handle_connected
- Uses find_each for memory efficiency when iterating channels
- Checkbox uses onchange="this.form.requestSubmit()" for immediate toggle
- System tests have pre-existing Ferrum::DeadBrowserError flakiness (environmental, not related to this feature)

---

### Session 2025-12-01 (continued)

**Feature**: 25-connection-health-check
**Status**: Completed

**What was done**:
- Created ConnectionHealthCheckJob with perform method to detect stale connections
- Job queries servers with connected_at set, then checks against IRC service status endpoint
- Stale connections (in DB but not in IRC service) are marked disconnected with proper cleanup
- Handles ServiceUnavailable by marking all servers disconnected (returns empty array)
- Added recurring schedule in config/recurring.yml (every 30 seconds for production/development)
- Added initializer that enqueues job on Rails boot (skipped in test environment)
- Status endpoint already returns connected server IDs in correct format
- Added 4 job tests (marks stale, keeps valid, handles unavailable, does nothing when none)
- Added 1 controller test for status endpoint returning server IDs
- Added 1 integration test for complete flow
- Passed QA review

**Notes for next session**:
- Use `stub` method instead of `instance_variable_get` for testing (per conventions)
- The job uses `find_each` for memory efficiency when iterating servers
- ServiceUnavailable is caught and results in empty connections list (marks all as stale)

---

### Session 2025-12-01 (continued)

**Feature**: 26-message-send-failure-handling
**Status**: Completed

**What was done**:
- Added `Server#mark_disconnected!` method that encapsulates disconnect logic in a transaction
- Updated `IrcEventHandler#handle_disconnected` to use the new method
- Refactored `MessagesController#send_irc_command` to return true/false for success/failure
- Updated `send_message`, `send_irc_action`, `send_pm` to send IRC command FIRST, then create message only on success
- On ConnectionNotFound (404): mark server disconnected, show "Connection lost" flash, redirect to server
- On ServiceUnavailable: show error, redirect back without disconnecting server
- Added 4 model tests for `mark_disconnected!`
- Updated 2 controller tests and added 2 new ones for error handling
- Added 2 integration tests for complete flow
- Passed QA review

**Notes for next session**:
- All planned features are now complete!
- `Server#mark_disconnected!` wraps all disconnect logic in a transaction for consistency
- `send_irc_command` returns boolean - this allows clean early returns without exceptions

---

### Session 2025-12-02

**Feature**: 27-fix-kick-updates-joined-state
**Status**: Completed

**What was done**:
- Updated `IrcEventHandler#handle_kick` to check if kicked user is server's own nickname
- When we are kicked: set `channel.joined = false` and clear all channel_users with `destroy_all`
- Used `casecmp?` for case-insensitive nickname comparison (IRC nicknames are case-insensitive)
- Added 3 unit tests for handle_kick behavior
- Added 1 integration test for kick updating channel view
- Passed QA review

**Notes for next session**:
- Next feature is `28-realtime-channel-joined-status.md` which depends on this fix
- The fix mirrors existing behavior in `handle_part` when source_nick matches server nickname

---

### Session 2025-12-02 (continued)

**Feature**: 28-realtime-channel-joined-status
**Status**: Completed

**What was done**:
- Added `Turbo::Broadcastable` include and `after_update_commit :broadcast_joined_status` callback to Channel model
- Created `broadcast_joined_status` private method that broadcasts to 4 targets (header, banner, input on channel stream; channels on server stream)
- Extracted channel show page into partials: `_header.html.erb`, `_banner.html.erb`, `_input.html.erb` with Turbo target IDs
- Extracted server channels list into `_channels.html.erb` partial with Turbo target ID
- Updated channel show view and server show view to use the new partials
- Fixed banner partial to avoid breaking CSS child selector (`& > .not-joined-banner`)
- Added 3 model tests for broadcast behavior (to channel stream, to server stream, no broadcast when unchanged)
- Added 4 integration tests for real-time updates via IrcEventHandler
- Passed QA review

**Notes for next session**:
- CSS uses child selectors (`& > .element`), so Turbo target wrapper divs must have the appropriate class for styling
- Banner partial conditionally renders either empty div (when joined) or styled div (when not joined) with same ID
- Uses `ActionView::RecordIdentifier.dom_id` for consistent target IDs in model callbacks

---

### Session 2025-12-02 (continued)

**Feature**: 29-dismiss-flash-on-status-change
**Status**: Completed

**What was done**:
- Updated application layout to wrap flash messages in divs with IDs (`flash_notice`, `flash_alert`) as Turbo Stream targets
- Added flash clearing to `Server#broadcast_connection_status` using `broadcast_replace_to` with empty HTML
- Added 2 integration tests for flash dismissal on connect/disconnect events
- Added 1 system test for verifying flash disappears in browser after connection completes
- Configured WebMock globally in `ApplicationSystemTestCase` to allow localhost (fixes system test conflicts)
- Passed QA review

**Notes for next session**:
- Flash wrapper divs always exist (even when empty) so Turbo Streams always have a target
- Using `broadcast_replace_to` with `html: ""` clears the flash content while keeping the target div
- WebMock configuration in `ApplicationSystemTestCase` is `WebMock.disable_net_connect!(allow_localhost: true)` to allow Capybara to communicate with local Puma server while still blocking external HTTP requests
