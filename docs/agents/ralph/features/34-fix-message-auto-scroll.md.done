# Fix Message Auto-Scroll

## Description

Messages in the channel view don't auto-scroll to the bottom when new messages arrive. The message-list Stimulus controller exists but isn't properly connected to the DOM.

## Root Cause

The `message-list` controller expects a target called `messages` (`data-message-list-target="messages"`), but this attribute is missing from the view. The controller falls back gracefully when `hasMessagesTarget` is false, but this means no scrolling or new message detection happens.

Additionally, the MutationObserver watches `messagesTarget` for `childList` changes, but Turbo appends messages to the nested `#messages` div, not the observed element.

## Behavior

### Auto-scroll when at bottom
- If user is scrolled to the bottom (within 50px threshold), new messages should auto-scroll the view to show them
- The controller already has this logic in `messageAdded()` - it just needs the target connected

### Preserve scroll position when reading history
- If user has scrolled up to read history, new messages should NOT auto-scroll
- Instead, show the "New messages below" indicator
- Clicking the indicator scrolls to bottom and hides it

### Auto-scroll on sending a message
- When the user sends a message, always scroll to bottom
- This requires the message form to trigger a scroll action on submit

## Implementation

### 1. Fix target attribute in channel view

In `app/views/channels/show.html.erb`, the `.messages` div needs the correct target:

```erb
<div class="messages"
     data-controller="message-list"
     data-message-list-target="messages"
     data-channel-target="messages"
     data-message-list-channel-id-value="<%= @channel.id %>">
```

Note: Keep both targets - `channel` controller also uses it.

### 2. Fix MutationObserver to watch nested content

The observer should either:
- Watch the inner `#messages` div for new children, OR
- Add `subtree: true` to the observer options

Recommended approach: change the observer to watch the inner div by adding a second target.

Update controller:
```javascript
static targets = ["messages", "container", "newIndicator"]

observeNewMessages() {
  if (!this.hasContainerTarget) return

  const observer = new MutationObserver((mutations) => {
    for (const mutation of mutations) {
      if (mutation.type === "childList" && mutation.addedNodes.length > 0) {
        this.messageAdded()
      }
    }
  })

  observer.observe(this.containerTarget, { childList: true })
}
```

And update the view to add target to inner div:
```erb
<div id="messages" data-message-list-target="container">
```

### 3. Scroll on message send

Add a method to the controller that the form can call:

```javascript
sent() {
  this.scrollToBottom()
  this.atBottom = true
}
```

Wire up in the message form to call this on successful submit. The message form controller should call `message-list#sent` after submission.

### 4. Same fix for conversation view

Apply the same changes to `app/views/conversations/show.html.erb` for PM views.

## Tests

### System Tests

**Auto-scroll on new message when at bottom**
- Given: User is viewing a channel, scrolled to bottom
- When: New message arrives via Turbo Stream
- Then: View scrolls to show the new message

**No scroll when reading history**
- Given: User is viewing a channel, scrolled up 200px
- When: New message arrives via Turbo Stream
- Then: View does NOT scroll
- And: "New messages below" indicator is visible

**Click indicator to scroll**
- Given: "New messages below" indicator is visible
- When: User clicks indicator
- Then: View scrolls to bottom
- And: Indicator is hidden

**Scroll on send**
- Given: User is scrolled up reading history
- When: User types and sends a message
- Then: View scrolls to bottom

### Controller Tests (JavaScript)

**isAtBottom detection**
- When scrollTop + clientHeight >= scrollHeight - 50, returns true
- When scrolled up more than 50px, returns false

**messageAdded behavior**
- When atBottom is true, calls scrollToBottom
- When atBottom is false, calls showNewIndicator

## Dependencies

None - this is a bugfix for existing functionality.
