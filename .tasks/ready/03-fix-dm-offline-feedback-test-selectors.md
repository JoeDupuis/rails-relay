---
title: Fix DM offline feedback test selectors
tags: [bug]
priority: medium
created: 2026-02-21
depends_on: []
branch: ""
---

## Summary

Three DM offline feedback system tests fail because they use `input[name='content']` selectors, but the message form was changed from a text field to a textarea in commit `dce3124`. Update all four CSS selectors in the test file from `input[name='content']` to `textarea[name='content']`.

## Detailed Description

Commit `dce3124` ("Replace message input with auto-expanding textarea") changed `f.text_field :content` to `f.text_area :content` in `app/views/messages/_form.html.erb`. This changed the rendered HTML from `<input type="text" name="content">` to `<textarea name="content">`. The DM offline feedback system tests were not updated to match.

There are four selectors to fix:
- Line 33: `assert_no_selector "input[name='content']"` — passes accidentally (no input exists, but the intent is to verify no message input when user is offline)
- Line 52: `assert_selector "input[name='content']"` — **fails**
- Line 94: `assert_selector "input[name='content']", wait: 5` — **fails**
- Line 112: `assert_selector "input[name='content']"` — **fails**

## Approach

Find-and-replace all occurrences of `input[name='content']` with `textarea[name='content']` in the test file.

### Files

- `test/system/dm_offline_feedback_test.rb` — replace 4 occurrences of `input[name='content']` with `textarea[name='content']`

## Testing Strategy

### Feedback Loop

```
bin/rails test test/system/dm_offline_feedback_test.rb
```

### System Tests

- Run all three DM offline feedback tests and confirm they pass
- The `assert_no_selector` on line 33 should still pass (correctly this time — asserting no textarea when user is offline)
- The three `assert_selector` calls should now find the textarea element

## Acceptance Criteria

- [ ] All four `input[name='content']` selectors replaced with `textarea[name='content']`
- [ ] All three DM offline feedback system tests pass
- [ ] No other tests broken

## Session Log

_Agents append context here as they work. This persists across sessions._
