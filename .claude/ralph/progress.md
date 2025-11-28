# Progress Log

## Current State

Project not yet started. Features are spec'd and ready for implementation.

---

## Feature Overview

### Phase 1: Authentication & Foundation
1. `auth-signin.md` - User login via Rails auth generator
2. `auth-multitenant.md` - Per-user database isolation

### Phase 2: Server Management
3. `server-crud.md` - Add, edit, delete IRC servers

### Phase 3: IRC Process
4. `process-spawn.md` - Spawning and managing IRC processes
5. `process-ipc.md` - Communication between Rails and IRC processes

### Phase 4: Channels & Messages
6. `channels.md` - Join, leave, list channels
7. `messages-receive.md` - Receiving messages from IRC
8. `messages-send.md` - Sending messages to IRC
9. `messages-history.md` - Message history and scrollback
10. `pm-view.md` - Private message conversations

### Phase 5: Notifications
11. `notifications-unread.md` - Unread tracking and badges
12. `notifications-highlights.md` - Highlights and browser notifications

### Phase 6: UI
13. `ui-layout.md` - Main application layout
14. `ui-server-view.md` - Server details page
15. `ui-channel-view.md` - Channel message view

### Phase 7: Media
16. `media-upload.md` - Image upload via ActiveStorage

---

## Session History

_No sessions yet._

---

## Suggested Next Feature

Start with `auth-signin.md` - this sets up Rails authentication which everything else depends on.
