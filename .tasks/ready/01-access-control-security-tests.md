---
title: Add access control and security tests
tags: [test, security]
priority: high
created: 2026-02-21
depends_on: []
branch: ""
---

## Summary

Add comprehensive access control and security tests across the application. This covers three areas: (1) cross-user access control tests verifying that one user cannot access another user's resources, added to 6 existing controller test files; (2) an auth sweep integration test verifying all authenticated controllers reject unauthenticated requests; (3) wrong-secret tests for 4 internal API controllers. No production code changes — tests only.

## Detailed Description

### Cross-User Access Control Tests

Every controller that accesses user-owned resources scopes queries through `Current.user`. If a user tries to access another user's resource, `find` raises `ActiveRecord::RecordNotFound` which Rails renders as 404. Several controllers already have cross-user tests, but coverage is incomplete.

**Already covered** (do not duplicate):
- ChannelsController: `show`
- ConversationsController: `show`, `create`
- Conversation::MessagesController: `create`
- Conversation::ClosuresController: `create`
- MessagesController: channel-scoped `create`
- NotificationsController: `index`, `update`
- UploadsController: `create`

**Missing and needed:**

| Controller | Actions to test | Notes |
|---|---|---|
| ServersController | `show`, `edit`, `update`, `destroy` | All use `Current.user.servers.find(params[:id])` |
| ConnectionsController | `create`, `destroy` | Uses `Current.user.servers.find(params[:server_id])` |
| ChannelsController | `create`, `update`, `destroy` | `create` scopes via `set_server`; `update`/`destroy` scope via `set_channel` with join on user_id |
| MessagesController | `index`, server-scoped `create` | `index` is channel-scoped (`GET /channels/:id/messages`) and requires `before_id` param. Server-scoped create is `POST /servers/:id/messages` |
| Conversation::MessagesController | `index` | Requires `before_id` param. `GET /conversations/:id/messages?before_id=X` |
| IsonsController | `show` (data isolation) | Different pattern — `GET /ison` is a collection endpoint, not a resource endpoint. Test that calling it as user A does not affect user B's conversations |

### Auth Sweep Integration Test

A single test file that hits one GET endpoint per authenticated controller without a session, verifying redirect to `/session/new`. This catches any controller that accidentally adds `allow_unauthenticated_access`.

Endpoints to test:
- `GET /` (HomeController)
- `GET /servers` (ServersController)
- `GET /channels/:id` (ChannelsController)
- `GET /channels/:id/messages?before_id=1` (MessagesController)
- `GET /conversations/:id` (ConversationsController)
- `GET /conversations/:id/messages?before_id=1` (Conversation::MessagesController)
- `GET /notifications` (NotificationsController)
- `GET /ison` (IsonsController)

For endpoints with resource IDs, create resources directly (e.g., `servers(:joes_server).channels.first`) without signing in. The auth check runs before resource lookup, so the redirect happens regardless of whether the resource exists.

### Internal API Wrong-Secret Tests

Four internal controllers only test the "missing secret" case. Add tests for "wrong secret" (providing `Authorization: Bearer wrong_value`), verifying 401. The `InternalApiAuthentication` concern uses `secure_compare` which should reject incorrect tokens.

Controllers needing wrong-secret tests:
- `Internal::Irc::CommandsController`
- `Internal::Irc::EventsController`
- `Internal::Irc::StatusController`
- `Internal::Irc::IsonsController`

(`Internal::Irc::ConnectionsController` already has both missing and wrong-secret tests.)

## Approach

Follow existing test patterns in the codebase. All cross-user tests follow the same shape:

```ruby
test "user cannot X another user's Y" do
  server = servers(:joes_server)  # or create inline
  sign_in_as(users(:jane))

  get/post/patch/delete some_path(resource)
  assert_response :not_found
end
```

**No webmock stubs needed** for cross-user tests. The `Current.user.servers.find()` call raises `RecordNotFound` before any IRC service call is made.

**Wrong-secret tests** follow the existing pattern in `connections_controller_test.rb`:
```ruby
test "POST with wrong secret returns 401" do
  post path, params: params, headers: { "Authorization" => "Bearer wrong_secret" }
  assert_response :unauthorized
end
```

**IsonsController** is a special case. It's a collection endpoint that scopes via `Current.user.servers`. The test should verify data isolation: create conversations for both users, call `GET /ison` as one user, and assert only that user's conversations are affected.

### Files

- `test/controllers/servers_controller_test.rb` — add 4 cross-user tests
- `test/controllers/connections_controller_test.rb` — add 2 cross-user tests
- `test/controllers/channels_controller_test.rb` — add 3 cross-user tests
- `test/controllers/messages_controller_test.rb` — add 2 cross-user tests
- `test/controllers/conversation/messages_controller_test.rb` — add 1 cross-user test
- `test/controllers/isons_controller_test.rb` — add 1 data isolation test
- `test/controllers/internal/irc/commands_controller_test.rb` — add 1 wrong-secret test
- `test/controllers/internal/irc/events_controller_test.rb` — add 1 wrong-secret test
- `test/controllers/internal/irc/status_controller_test.rb` — add 1 wrong-secret test
- `test/controllers/internal/irc/isons_controller_test.rb` — add 1 wrong-secret test
- `test/integration/auth_sweep_test.rb` — **create**, 8 unauthenticated redirect tests

## Testing Strategy

This task IS the tests. The feedback loop is:

1. Write tests in the target file
2. Run: `bin/rails test test/path/to/file.rb`
3. Verify all new tests pass
4. Run full suite at the end: `bin/rails test`

### Integration Tests

**Cross-user tests (13 tests across 6 files):**

ServersController:
- Given joe owns a server, jane is signed in → GET /servers/:id → 404
- Given joe owns a server, jane is signed in → GET /servers/:id/edit → 404
- Given joe owns a server, jane is signed in → PATCH /servers/:id → 404
- Given joe owns a server, jane is signed in → DELETE /servers/:id → 404

ConnectionsController:
- Given joe owns a server, jane is signed in → POST /servers/:id/connection → 404
- Given joe owns a server, jane is signed in → DELETE /servers/:id/connection → 404

ChannelsController:
- Given joe owns a server, jane is signed in → POST /servers/:id/channels → 404
- Given joe owns a channel, jane is signed in → PATCH /channels/:id → 404
- Given joe owns a channel, jane is signed in → DELETE /channels/:id → 404

MessagesController:
- Given joe owns a channel with messages, jane is signed in → GET /channels/:id/messages?before_id=X → 404
- Given joe owns a server, jane is signed in → POST /servers/:id/messages → 404

Conversation::MessagesController:
- Given joe owns a conversation with messages, jane is signed in → GET /conversations/:id/messages?before_id=X → 404

IsonsController:
- Given joe and jane each have conversations on their own servers, jane is signed in → GET /ison → only jane's conversations are affected, joe's are untouched

**Auth sweep tests (8 tests, 1 new file):**
- For each authenticated GET endpoint: no session → GET endpoint → 302 redirect to /session/new

**Internal API wrong-secret tests (4 tests across 4 files):**
- For each internal controller: POST/GET with `Authorization: Bearer wrong_secret` → 401

## Acceptance Criteria

- [ ] ServersController has cross-user tests for show, edit, update, destroy
- [ ] ConnectionsController has cross-user tests for create, destroy
- [ ] ChannelsController has cross-user tests for create, update, destroy
- [ ] MessagesController has cross-user tests for index and server-scoped create
- [ ] Conversation::MessagesController has cross-user test for index
- [ ] IsonsController has data isolation test
- [ ] Auth sweep test covers all 8 authenticated GET endpoints
- [ ] 4 internal API controllers have wrong-secret tests
- [ ] All new tests pass (`bin/rails test`)
- [ ] Full test suite passes with no regressions

## Session Log

_Agents append context here as they work. This persists across sessions._
