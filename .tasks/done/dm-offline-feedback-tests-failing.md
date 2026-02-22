---
title: DM offline feedback system tests can't find message input
tags: [bug]
priority: medium
created: 2026-02-21
---

Three DM offline feedback system tests fail because they can't find `input[name='content']` in the expected container. Likely a shared root cause — the input element is either missing or in a different location than the test expects.

## Observed Behavior
Tests fail with: `expected to find css "input[name='content']"` but there were no matches.

## Expected Behavior
The DM message input should be present and findable by the tests.

## Failing Tests
1. `test/system/dm_offline_feedback_test.rb:37` — DM with online user shows enabled input
2. `test/system/dm_offline_feedback_test.rb:78` — DM input enables when user comes online via ISON
3. `test/system/dm_offline_feedback_test.rb:98` — DM input disables when user goes offline via ISON
