# Fix Server Page Layout on Mobile

## Description

On tablet/mobile viewports (< 1024px), the server show page content appears squeezed into a narrow column on the left side of the screen, as if it's being rendered in the sidebar grid area instead of the main content area.

## Root Cause

CSS specificity issue in `app/assets/stylesheets/components/app-layout.css`:

```css
.app-layout {
  grid-template-columns: var(--sidebar-width) 1fr var(--userlist-width);

  &.-no-userlist {
    grid-template-columns: var(--sidebar-width) 1fr;  /* specificity: 2 classes */
  }

  @media (max-width: 1023px) {
    grid-template-columns: 1fr;  /* specificity: 1 class - LOSES to -no-userlist! */
  }
}
```

The `-no-userlist` modifier has higher specificity (2 classes) than the media query rule (1 class), so even on mobile, pages without a userlist (like the server show page) still get `grid-template-columns: var(--sidebar-width) 1fr` instead of `1fr`.

This makes the main content area only `1fr` wide with the first column being `var(--sidebar-width)` (240px), but since the sidebar is `position: fixed` on mobile, that first column is empty - causing the content to appear offset or squeezed.

## Behavior

### Desktop (>= 1024px)
- Server show page uses 2-column grid: sidebar | main
- Main content fills remaining space
- No userlist column (server page doesn't have one)

### Tablet/Mobile (< 1024px)
- Server show page uses 1-column grid
- Sidebar is fixed overlay (slide-in)
- Main content fills full width
- Works same as channel view on mobile

## Implementation

Fix the CSS specificity by including `-no-userlist` in the media query:

```css
.app-layout {
  display: grid;
  grid-template-rows: var(--header-height) 1fr;
  grid-template-columns: var(--sidebar-width) 1fr var(--userlist-width);
  height: 100vh;
  background: var(--color-background);

  /* ... other rules ... */

  &.-no-userlist {
    grid-template-columns: var(--sidebar-width) 1fr;
  }

  @media (max-width: 1023px) {
    &, &.-no-userlist {  /* Include -no-userlist to match specificity */
      grid-template-columns: 1fr;
    }

    /* ... rest of media query rules ... */
  }
}
```

Alternatively, use `!important` on the media query (less preferred):
```css
@media (max-width: 1023px) {
  grid-template-columns: 1fr !important;
}
```

## Tests

### System Tests

**Server page layout on mobile viewport**
- Given: Viewport width is 768px (mobile)
- When: User views server show page
- Then: Main content fills full viewport width
- And: Content is not offset or squeezed to left side

**Server page layout on tablet viewport**
- Given: Viewport width is 900px (tablet)
- When: User views server show page
- Then: Main content fills full viewport width (sidebar is overlay)

**Server page layout on desktop viewport**
- Given: Viewport width is 1200px (desktop)
- When: User views server show page
- Then: Sidebar visible on left (240px)
- And: Main content fills remaining space

**Channel page still works on mobile**
- Given: Viewport width is 768px
- When: User views channel show page
- Then: Main content fills full width
- And: Userlist is hidden (CSS display: none)

### Visual Regression

Take screenshots of server show page at:
- 375px (mobile phone)
- 768px (tablet portrait)
- 1024px (tablet landscape/small desktop)
- 1440px (desktop)

Compare before/after to ensure fix works and doesn't break other pages.

## Dependencies

None - this is a CSS bugfix.
