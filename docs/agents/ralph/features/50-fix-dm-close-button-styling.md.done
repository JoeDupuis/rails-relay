# Fix DM Close Button Styling and Hover Behavior

## Description

The close button (×) to leave a DM conversation was intended to appear only on hover and be styled. Currently it always shows and looks like a default HTML button.

## Current Behavior

1. Close button is always visible in the DM sidebar item
2. Button has default browser styling (looks like a gray button)
3. Hover behavior doesn't work as intended

## Expected Behavior

1. Close button should be hidden by default
2. Close button should appear only when hovering over the DM item
3. Button should be styled as a simple × icon without button chrome

## Root Cause

The `button_to` helper generates a `<form>` wrapper around the button:

```html
<form method="post" action="...">
  <button class="close-btn" type="submit">×</button>
</form>
```

The CSS uses `& > .close-btn` expecting the button to be a direct child of `.dm-item`, but the `<form>` is in between. The selector doesn't match.

## Files to Modify

- `app/views/shared/_conversation_sidebar_item.html.erb` - Fix button markup
- `app/assets/stylesheets/components/dm-item.css` - Update styles for nested button

## Solution Options

### Option A: Update CSS to target through form (Recommended)

Account for the form wrapper in the CSS selector:

```css
.dm-item {
  & > form > .close-btn {
    opacity: 0;
    background: none;
    border: none;
    cursor: pointer;
    padding: var(--space-xs) var(--space-sm);
    color: var(--color-text-muted);
    font-size: var(--font-lg);
    line-height: 1;
    flex-shrink: 0;
  }

  & > form > .close-btn:hover {
    color: var(--color-text);
  }

  &:hover > form > .close-btn {
    opacity: 1;
  }
}
```

Also style the form to not break flex layout:

```css
.dm-item {
  & > form {
    display: contents; /* or flex-shrink: 0 */
  }
}
```

### Option B: Use link_to with Turbo method

Replace `button_to` with `link_to` - no form wrapper, simpler CSS:

```erb
<%= link_to "×", conversation_closure_path(conversation),
    data: { turbo_method: :post },
    class: "close-btn",
    aria: { label: "Close conversation" } %>
```

CSS stays as-is since link is direct child of `.dm-item`.

## Implementation

Either option works. Option B is simpler (no form wrapper to deal with), but Option A keeps the conventional `button_to` for POST actions.

## Tests

### System Tests

**Close button hidden by default**
1. Sign in
2. Navigate to page with DM in sidebar
3. Verify close button is not visible (opacity 0 or visibility hidden)

**Close button appears on hover**
1. Sign in
2. Navigate to page with DM in sidebar
3. Hover over DM item
4. Verify close button becomes visible

**Close button styled correctly**
1. Sign in
2. Navigate to page with DM in sidebar
3. Hover over DM item
4. Verify close button has no button chrome (no border, no background)
5. Verify close button is × character in muted color

**Close button hover state**
1. Sign in
2. Hover over DM item
3. Hover over close button
4. Verify button color changes to darker text color

**Close button functions**
1. Sign in
2. Navigate to page with DM in sidebar
3. Hover and click close button
4. Verify DM is removed from sidebar
5. Verify redirect to server page

## Dependencies

41-close-dm-conversations.md.done (close button functionality already implemented)

## Implementation Notes

- `button_to` generates a form wrapper; `link_to` with `turbo_method: :post` does not
- `display: contents` on the form makes it invisible to flex layout (children act as direct children of parent)
- Test the hover behavior carefully - CSS `:hover` on parent selectors can be tricky
- The close button should remain accessible via keyboard (tab navigation)
