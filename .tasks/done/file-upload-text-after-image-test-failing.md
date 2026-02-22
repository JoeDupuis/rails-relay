---
title: Text message after image upload test fails - only finds 1 message instead of 2
tags: [bug]
priority: medium
created: 2026-02-21
---

The file upload system test expects two `.message-item` elements after sending an image then a text message, but only finds one (the image link).

## Observed Behavior
`expected to find visible css ".message-item" 2 times, found 1 match` — only the image upload message appears, the follow-up text message is missing.

## Expected Behavior
Both the image upload message and the subsequent text message should appear as separate `.message-item` elements.

## Steps to Reproduce
1. Run `bin/rails test test/system/file_upload_test.rb:37`
