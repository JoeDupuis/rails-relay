---
title: Own message unread badge test fails - sent message not appearing
tags: [bug]
priority: medium
created: 2026-02-21
---

The test expects to find a `.message-item` with text "Hello from me" after sending a message, but only finds a system message. The user's own message doesn't appear in the channel.

## Observed Behavior
`expected to find visible css ".message-item" with text "Hello from me"` — no match. Only a system "Initial message" is present.

## Expected Behavior
After sending a message, it should appear as a `.message-item` in the channel.

## Steps to Reproduce
1. Run `bin/rails test test/system/own_message_unread_badge_test.rb:13`
