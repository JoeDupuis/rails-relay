---
title: Fix IRC command stubs and extract shared helper
tags: [bug]
priority: medium
created: 2026-02-21
depends_on: []
branch: ""
---

## Summary

Several system tests silently fail to create messages because their WebMock stubs return `{ success: true }` instead of `{ parts: [...] }`. The `send_message` controller method does `return unless parts`, so the message is never created and the Turbo broadcast never fires. Fix this by extracting a shared `stub_irc_command` helper and applying it to all affected tests.

## Detailed Description

### Root cause

`InternalApiClient.send_command` parses the JSON response body and returns `body["parts"]`. When a stub returns `{ success: true }` (no `parts` key), the return value is `nil`. The controller's `send_message` method does `return unless parts`, silently skipping message creation.

### Affected tests

These system tests send text messages through the form and assert they appear, but use stubs without `parts`:

- `test/system/file_upload_test.rb` — second test ("text message after image upload sends text not image link") fails visibly
- `test/system/own_message_unread_badge_test.rb` — sends "Hello from me", asserts it appears
- `test/system/unified_view_test.rb` — "DM message sending still works" sends "Hello from test"

The first test in `file_upload_test.rb` passes because `handle_file_upload` creates the Message directly without going through `send_message`.

### Existing correct pattern

Four controller/integration test files already have the correct dynamic stub inline:

- `test/controllers/messages_controller_test.rb`
- `test/controllers/conversation/messages_controller_test.rb`
- `test/integration/message_flow_test.rb`
- `test/integration/pm_flow_test.rb`

These use this pattern:
```ruby
stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
  .to_return do |request|
    body = JSON.parse(request.body)
    message = body.dig("params", "message")
    parts = message ? [message] : true
    { status: 202, body: { parts: parts }.to_json, headers: { "Content-Type" => "application/json" } }
  end
```

Note the `message ? [message] : true` fallback — commands without a `message` param (join, part, nick) return `parts: true` so callers don't get nil.

## Approach

1. Create a shared test helper with `stub_irc_command` that uses the dynamic echo pattern
2. Include it in the test suite so all test types can use it
3. Replace the broken stubs in the three system test files
4. Replace the inline dynamic stubs in the four controller/integration test files to DRY up

Do NOT touch test files that use intentionally different stubs (error responses, specific split parts, etc.) — those are testing edge cases.

### Files

- `test/test_helpers/irc_command_stub_helper.rb` — create: shared `stub_irc_command` method
- `test/test_helper.rb` — include the new helper (check how other helpers in `test/test_helpers/` are included)
- `test/system/file_upload_test.rb` — replace stub with `stub_irc_command`
- `test/system/own_message_unread_badge_test.rb` — replace stub with `stub_irc_command`
- `test/system/unified_view_test.rb` — replace stub with `stub_irc_command`
- `test/controllers/messages_controller_test.rb` — replace inline dynamic stub with `stub_irc_command`
- `test/controllers/conversation/messages_controller_test.rb` — replace inline dynamic stub with `stub_irc_command`
- `test/integration/message_flow_test.rb` — replace inline dynamic stub with `stub_irc_command`
- `test/integration/pm_flow_test.rb` — replace inline dynamic stub with `stub_irc_command`

## Testing Strategy

### Feedback loop

Primary (the originally reported failing test):
```
bin/rails test test/system/file_upload_test.rb:37
```

### Verification

Run all affected test files to confirm nothing broke:
```
bin/rails test test/system/file_upload_test.rb test/system/own_message_unread_badge_test.rb test/system/unified_view_test.rb test/controllers/messages_controller_test.rb test/controllers/conversation/messages_controller_test.rb test/integration/message_flow_test.rb test/integration/pm_flow_test.rb
```

Broad sanity check:
```
bin/rails test test/system/ test/controllers/ test/integration/
```

No new tests needed — this is a test infrastructure fix verified by existing tests passing.

## Acceptance Criteria

- [ ] `bin/rails test test/system/file_upload_test.rb:37` passes
- [ ] All three affected system tests pass with the shared helper
- [ ] All four controller/integration tests pass after refactoring to shared helper
- [ ] No other tests break (full system + controller + integration suite green)
- [ ] The shared helper uses the dynamic echo pattern with `message ? [message] : true` fallback

## Session Log

_Agents append context here as they work._
