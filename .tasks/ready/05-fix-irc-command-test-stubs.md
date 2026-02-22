---
title: Fix IRC command test stubs returning empty bodies
tags: [bug]
priority: medium
created: 2026-02-21
depends_on: []
branch: ""
---

## Summary

Multiple test files stub `POST /internal/irc/commands` with an empty body (`body: ""`), but `InternalApiClient.send_command()` expects JSON with a `parts` key. This causes tests that send messages via the UI to fail because `send_message()` receives `nil` for parts and returns early without creating messages. Fix all broken stubs to return `{ parts: [...] }.to_json`.

## Detailed Description

### Root cause

`InternalApiClient.send_command()` parses the response body as JSON and extracts `body["parts"]`:

```ruby
body = JSON.parse(response.body) rescue {}
body["parts"]
```

When the stub returns `body: ""`, JSON parsing fails, `rescue` returns `{}`, and `body["parts"]` returns `nil`. Then `MessagesController#send_message()` hits `return unless parts` and never creates the message.

### Two categories of broken stubs

**Category A — Causes test failures**: Tests that send a message via the UI form and then assert the message appears in the DOM. These fail because the message is never created.

**Category B — Wrong but harmless**: Tests that stub the endpoint to satisfy WebMock but never exercise the message-sending code path. These don't fail today but should be fixed for correctness and to prevent future confusion.

## Approach

Use the dynamic `.to_return` block pattern already established in `messages_controller_test.rb` for tests that send messages. Use a simple static response for tests that just need a stub to exist.

### Dynamic pattern (for tests that send messages)

```ruby
stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
  .to_return { |request|
    body = JSON.parse(request.body)
    { status: 202, body: { parts: [body.dig("params", "message")].compact }.to_json }
  }
```

### Static pattern (for tests that just need a stub)

```ruby
stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
  .to_return(status: 202, body: { parts: [] }.to_json)
```

### Files

**Category A — Fix with dynamic pattern:**

- `test/system/own_message_unread_badge_test.rb` (line ~9-10) — sends message, expects it to appear
- `test/system/unified_view_test.rb` (line ~11-12) — sends DM, expects it to appear

**Category B — Fix with static pattern:**

- `test/system/dm_offline_feedback_test.rb` (lines ~11-12, ~41, ~102) — tests offline UI state, doesn't verify message creation
- `test/system/clickable_links_test.rb` (line ~7-8) — pre-creates messages, doesn't send via UI. Also fix status from 200 to 202
- `test/system/file_upload_test.rb` (line ~7-8) — file upload uses separate code path
- `test/integration/sidebar_test.rb` (line ~10-11)
- `test/integration/upload_flow_test.rb` (line ~10-11)
- `test/integration/dm_offline_feedback_test.rb` (line ~12-13, ~41, ~102)
- `test/integration/message_history_test.rb` (line ~10-11)
- `test/integration/channel_flow_test.rb` (line ~10-11)
- `test/integration/realtime_channel_status_test.rb` (line ~10-11)
- `test/integration/unread_indicators_test.rb` (line ~10-11)
- `test/integration/close_dm_flow_test.rb` (line ~10-11)
- `test/integration/server_page_test.rb` (line ~14-15)
- `test/controllers/channels_controller_test.rb` (line ~10-11)
- `test/controllers/uploads_controller_test.rb` (line ~10-11)
- `test/models/message_test.rb` (lines ~188, ~225, ~241) — also fix status from 200 to 202
- `test/models/irc_event_handler_test.rb` (lines ~543, ~584)
- `test/integration/auto_join_test.rb` (lines ~17, ~25, ~31)

### Pattern note

Before blindly replacing, verify each stub is actually for `/internal/irc/commands` (some tests stub multiple endpoints). Only change the command stubs, not connection stubs (`/internal/irc/connections`).

## Testing Strategy

### Feedback Loop

```
bin/rails test test/system/own_message_unread_badge_test.rb test/system/unified_view_test.rb --verbose
```

### Verification

1. Run the originally failing test to confirm it passes:
   ```
   bin/rails test test/system/own_message_unread_badge_test.rb
   ```

2. Run all system tests to verify no regressions:
   ```
   bin/rails test test/system/
   ```

3. Run the full test suite to verify nothing else broke:
   ```
   bin/rails test
   ```

## Acceptance Criteria

- [ ] `own_message_unread_badge_test.rb` passes — message appears after sending
- [ ] `unified_view_test.rb` passes — DM message appears after sending
- [ ] All other modified test files still pass
- [ ] No test regressions in the full suite
- [ ] All `/internal/irc/commands` stubs return valid JSON with a `parts` key

## Session Log

_Agents append context here as they work. This persists across sessions._
