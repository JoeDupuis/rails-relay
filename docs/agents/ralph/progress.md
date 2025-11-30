# Progress Log

## Current State

Feature `05-irc-connections` completed. IRC connection management with yaic gem.

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

## Suggested Next Feature

Continue with `06-channels.md` for channel management (join, leave, list).
