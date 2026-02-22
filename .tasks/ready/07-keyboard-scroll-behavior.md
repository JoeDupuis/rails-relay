---
id: 7
title: "Keep bottom scroll position when Android keyboard opens"
tags: [bug, ux, mobile, android]
priority: medium
created: 2026-02-08
depends_on: []
split_from: null
branch: ""
---

## Summary

On Android, when the soft keyboard opens (e.g. tapping the message input), the chat message list doesn't scroll to keep the bottom visible. The user loses sight of the most recent messages. The `message_list_controller` only triggers scroll-to-bottom on new messages, page load, and user send — it doesn't react to viewport resize caused by the keyboard.

## Detailed Description

### Current behavior

1. User is viewing a chat, scrolled to bottom
2. User taps the message input field
3. Android keyboard opens, `visualViewport.height` shrinks
4. `application.js` updates `--app-height` CSS variable, layout recalculates
5. Message list container shrinks but scroll position stays the same
6. Recent messages are now hidden behind/below the keyboard area

### Expected behavior

When the keyboard opens and the user was already at the bottom of the message list, the list should scroll to keep the bottom visible.

### Root cause

`message_list_controller.js` listens for:
- Page load → `scrollToBottom()`
- New message added (MutationObserver) → `scrollToBottom()` if `atBottom`
- User sends message → `scrollToBottom()`

It does NOT listen for viewport resize events. The `visualViewport.resize` event fires when the keyboard opens/closes, but nothing connects that to the message list scroll.

### Relevant architecture

- `app/javascript/controllers/application.js` — already listens to `visualViewport.resize` to set `--app-height`
- `app/javascript/controllers/message_list_controller.js` — owns scrolling logic, tracks `atBottom` state
- `app/views/messages/_form.html.erb` — message input textarea
- `.channel-view .messages` uses `flex: 1; overflow-y: auto` — shrinks when `--app-height` changes

## Approach

Add a `visualViewport.resize` listener in `message_list_controller.js`. When the viewport height decreases (keyboard opening) and the user was at bottom, call `scrollToBottom()` after a short delay to let layout settle.

### Implementation

In `message_list_controller.js`:

1. In `connect()`, add a `visualViewport.resize` listener
2. Track previous viewport height to detect shrink (keyboard open) vs grow (keyboard close)
3. On viewport shrink: if `atBottom`, wait ~100ms for layout, then `scrollToBottom()`
4. On viewport grow (keyboard close): same logic — keep bottom if was at bottom
5. In `disconnect()`, clean up the listener

### Files

- `app/javascript/controllers/message_list_controller.js` — add viewport resize listener and scroll logic

## Testing Strategy

### Feedback loop

This is a visual/behavioral bug on Android. Automated tests can verify the listener is wired up, but the real verification needs a device or emulator.

### Manual verification (required)

1. Open the app on an Android device or emulator
2. Navigate to a channel or DM with enough messages to scroll
3. Scroll to the bottom of the message list
4. Tap the message input field — keyboard opens
5. Verify the most recent messages remain visible (scrolled to bottom)
6. Close the keyboard — verify messages stay visible
7. Scroll UP from bottom, then tap input — verify it does NOT force-scroll to bottom (respects user's scroll position)

### Unit-level verification

Run the existing JS test suite to confirm no regressions:
```
bin/rails test test/system/
```

## Acceptance Criteria

- [ ] When at bottom of message list and keyboard opens, messages stay scrolled to bottom
- [ ] When at bottom and keyboard closes, messages stay scrolled to bottom
- [ ] When scrolled UP (not at bottom) and keyboard opens, scroll position is NOT forced to bottom
- [ ] Listener is cleaned up in `disconnect()`
- [ ] No regressions in existing system tests

## Session Log

_Agents append context here as they work. This persists across sessions._
