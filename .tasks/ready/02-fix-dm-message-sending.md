---
title: Fix DM message sending NoMethodError
tags: [bug]
priority: high
created: 2026-02-21
depends_on: []
branch: ""
---

## Summary

Sending a DM message crashes with `NoMethodError: undefined method 'map' for nil` because `Conversation::MessagesController#create` passes a nil `parts` value to `Message.create_outgoing!`. The nil comes from a broken test stub (wrong URL, wrong status code, empty body) that doesn't match, causing the generic setup stub (which returns an empty body) to handle the request. The fix is to correct the test stub and add a defensive nil guard in the controller for parity with the channel `MessagesController`.

## Detailed Description

### The bug chain

1. The system test at `test/system/unified_view_test.rb:69` stubs `http://localhost:3001/irc/commands` with `status: 200, body: ""`.
2. This stub has three defects:
   - **Wrong host/port**: test env uses `http://localhost:3000` (via `Rails.configuration.irc_service_url`), not `localhost:3001`
   - **Wrong path**: uses `/irc/commands` instead of `/internal/irc/commands`
   - **Wrong status**: uses `200` instead of `202` — `InternalApiClient.send_command` only returns `body["parts"]` on a 202; a 200 hits the else branch and raises `ServiceUnavailable`
3. Because the stub URL never matches, the setup stub at line 11 handles the request instead. That stub returns `status: 202, body: ""`.
4. `InternalApiClient.send_command` does `JSON.parse("") rescue {}` → `{}["parts"]` → `nil`.
5. `Conversation::MessagesController#create` passes `nil` to `Message.create_outgoing!(parts: nil)`.
6. `nil.map` raises `NoMethodError`.

### The real API works correctly

The full production chain (`Yaic::Client#privmsg` → `IrcConnection` → `IrcConnectionManager` → `Internal::Irc::CommandsController` → `InternalApiClient`) correctly returns `{ parts: ["message"] }`. The nil only occurs because of the broken test stub.

### Why the nil guard is still warranted

The channel `MessagesController` already guards against nil parts at line 82 (`return unless parts`). Adding the same guard to `Conversation::MessagesController` provides defensive consistency for edge cases (transient internal API issues, malformed responses).

## Approach

### 1. Fix the system test stub

In `test/system/unified_view_test.rb`, replace the broken stub at line 72 with one that:
- Uses `Rails.configuration.irc_service_url` for the host
- Uses the correct path `/internal/irc/commands`
- Returns status `202`
- Returns `{ parts: [message] }.to_json` with `Content-Type: application/json`

Follow the pattern from `test/controllers/conversation/messages_controller_test.rb` lines 10-16 which has a working stub.

### 2. Add nil guard in controller

In `Conversation::MessagesController#create`, add `next unless result` inside the `lines.each` loop, before the `Message.create_outgoing!` call.

### Files

- `test/system/unified_view_test.rb` — fix the stub at line 72 (URL, status, body)
- `app/controllers/conversation/messages_controller.rb` — add `next unless result` at line 33

## Testing Strategy

### Feedback loop

```
bin/rails test test/system/unified_view_test.rb:69
```

Run first to confirm failure, then after each change to verify.

### System test (fix existing)

The test at `unified_view_test.rb:69` ("sends and displays a DM message" or similar) is the primary verification. Once the stub is fixed, it should:
- Visit the DM conversation
- Fill in and submit a message
- Assert the message appears in the message list

### Integration test (add new)

Add one test to `test/controllers/conversation/messages_controller_test.rb`:

```
test "create handles nil response from IRC service gracefully"
  Given: A connected server with a DM conversation, IRC commands endpoint
         returns status 202 with body "{}" (valid JSON, no "parts" key)
  When:  POST to conversation_messages_path with content "Hello"
  Then:  Response succeeds (no 500 error)
         No new messages are created
         No NoMethodError raised
```

### Full regression

```
bin/rails test test/controllers/conversation/messages_controller_test.rb test/system/unified_view_test.rb
```

## Acceptance Criteria

- [ ] `bin/rails test test/system/unified_view_test.rb:69` passes
- [ ] New integration test for nil parts handling passes
- [ ] Full regression suite passes: `bin/rails test test/controllers/conversation/messages_controller_test.rb test/system/unified_view_test.rb`
- [ ] No `NoMethodError` when DM message is sent

## Session Log

_Agents append context here as they work. This persists across sessions._
