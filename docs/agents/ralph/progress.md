# Progress Log

## Current State

Feature `02-auth-multitenant` completed. Per-user database isolation implemented using activerecord-tenanted gem.

---

## Feature Overview

### Phase 1: Authentication & Foundation
1. `01-auth-signin.md` - User login via Rails auth generator
2. `02-auth-multitenant.md` - Per-user database isolation

### Phase 2: Server Management
3. `03-server-crud.md` - Add, edit, delete IRC servers

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

---

## Session History

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

## Suggested Next Feature

Continue with `03-server-crud.md` - implements full CRUD operations for IRC servers.
