---
title: DM message sending crashes with NoMethodError on nil
tags: [bug]
priority: high
created: 2026-02-21
---

Sending a DM message raises `NoMethodError: undefined method 'map' for nil` in `Message.create_outgoing!` (app/models/message.rb:18).

## Observed Behavior
Error when posting to `/conversations/1/messages`. The `create_outgoing!` method calls `.map` on a nil value.

## Expected Behavior
DM messages send successfully.

## Steps to Reproduce
1. Run `bin/rails test test/system/unified_view_test.rb:69`

## Stack Trace
```
app/models/message.rb:18:in `create_outgoing!'
app/controllers/conversation/messages_controller.rb:33:in `block in create'
app/controllers/conversation/messages_controller.rb:26:in `each'
app/controllers/conversation/messages_controller.rb:26:in `create'
```
