---
paths: **/*.{erb,css}
---

# CSS Conventions

## Simple

I would like to minimize the amount of html and css where possible. We can use modern css feature such as flex and grids to help minimize.

I like to use CSS instead of JS where possible.

# Component libraries

When a component is reused throughout the app we should maintain instructions in docs/components where every components as its own instructions in markdown with examples on how to use.

# RSCSS (Reasonable System for CSS Stylesheet Structure)

A systematic approach to writing maintainable CSS. This guide provides explicit rules for structuring CSS in a component-based architecture.

## IMPORTANT: Pure CSS Only

**All code examples use pure CSS with native CSS nesting.** No preprocessors (Sass, Less, etc.) are used. Modern browsers support CSS nesting natively using the `&` selector.

---

## Core Philosophy

RSCSS organizes CSS around **components** (UI pieces), **elements** (parts within components), and **variants** (modifications). This prevents class name conflicts and keeps CSS maintainable at scale.

**Key Principles:**
- Each component lives in its own file
- Components are self-contained and independent
- Components should NOT reference other components in their styles
- Use CSS variables for reusable colors and spacing

---

## 0. CSS Variables for Design Tokens

### Extract Reusable Values
All colors, spacing, and other reusable values **MUST** be defined as CSS variables in a central location (e.g., `variables.css` or `:root`).

### Use Broad, Non-Specific Names
Variable names should be **generic and reusable**, not tied to specific use cases.

#### ✓ GOOD: Broad, reusable names
```css
:root {
  /* Colors */
  --color-primary: #3490dc;
  --color-secondary: #6574cd;
  --color-success: #38c172;
  --color-danger: #e3342f;
  --color-warning: #f6993f;
  --color-neutral: #6c757d;

  --color-gray-100: #f8f9fa;
  --color-gray-200: #e9ecef;
  --color-gray-300: #dee2e6;
  --color-gray-900: #212529;

  /* Spacing */
  --space-xs: 0.25rem;
  --space-sm: 0.5rem;
  --space-md: 1rem;
  --space-lg: 1.5rem;
  --space-xl: 2rem;
  --space-2xl: 3rem;

  /* Typography */
  --font-sm: 0.875rem;
  --font-base: 1rem;
  --font-lg: 1.125rem;
  --font-xl: 1.25rem;

  /* Border radius */
  --radius-sm: 0.125rem;
  --radius-md: 0.25rem;
  --radius-lg: 0.5rem;
  --radius-full: 9999px;
}
```

#### ✗ BAD: Specific, non-reusable names
```css
:root {
  --button-color: #3490dc; /* ✗ too specific */
  --sidebar-padding: 1rem; /* ✗ too specific */
  --header-blue: #3490dc; /* ✗ too specific */
}
```

### Using Variables in Components
```css
.search-button {
  background: var(--color-primary);
  padding: var(--space-md);
  border-radius: var(--radius-md);

  &.-large {
    padding: var(--space-lg);
    font-size: var(--font-lg);
  }
}
```

---

## 1. Components

### Definition
A component is an independent, reusable piece of UI. Think of each discrete UI element as a component.

### Naming Rules
- **MUST** use at least two words
- **MUST** separate words with dashes (kebab-case)
- Use descriptive names that indicate purpose

### Examples
```css
.like-button { }
.search-form { }
.article-card { }
.news-header { }
.vote-box { }
.rico-custom-header { }
```

### When You Can't Think of Two Words
If a component seems to only need one word, add a suffix to clarify its type:

Block-level suffixes:
- `.alert-box`
- `.alert-card`
- `.alert-block`

Inline suffixes:
- `.link-button`
- `.link-span`

### Component Independence
- **CRITICAL**: Each component **MUST** be in its own file
- Components **MUST NOT** reference other components in their CSS
- If you need to style a nested component, use variants (see Section 4)

---

## 2. Elements

### Definition
Elements are the parts inside a component. They are the building blocks of components.

### Naming Rules
- **MUST** use only one word
- **NO** dashes or underscores
- If multiple words are absolutely necessary, concatenate them without separators
- DO NOT mix element and variant. Element DO NOT have any dash in front of them.

### Selector Rules
- **PREFER** the child selector `>` over descendant selectors
- This prevents styles from bleeding into nested components
- Child selectors also perform better

### Examples
```css
.search-form {
  & > .field { /* ... */ }
  & > .action { /* ... */ }
  & > .button { /* ... */ }
}

.profile-box {
  & > .firstname { /* ... */ }
  & > .lastname { /* ... */ }
  & > .avatar { /* ... */ }
}
```

### Child Selector vs Descendant Selector
```css
.article-card {
  & .title { /* okay */ }
  & > .author { /* ✓ better */ }
}
```

### Avoid Tag Selectors
Use class names instead of tag selectors for better performance and clarity:

```css
.article-card {
  & > h3 { /* ✗ avoid */ }
  & > .name { /* ✓ better */ }
}
```

### Multi-word Elements
For elements that need two or more words, concatenate them without dashes or underscores:

```css
.profile-box {
  & > .firstname { /* ... */ }
  & > .lastname { /* ... */ }
  & > .avatar { /* ... */ }
}
```

---

## 3. Variants

### Definition
Variants are modifications of components or elements. They represent different states or appearances.

### Naming Rules
- **MUST** prefix with a dash (`-`)
- Can be applied to both components and elements
- Use descriptive names for the variation

### Why Dash Prefix?
- Prevents ambiguity with elements (elements have no prefix, variants have `-`)
- CSS class names can only start with a letter, `_`, or `-`
- Easier to type than underscore
- Resembles UNIX command switches (`gcc -O2 -Wall`)

### Component Variants
```css
.like-button {
  &.-wide { /* ... */ }
  &.-short { /* ... */ }
  &.-disabled { /* ... */ }
}

.search-form {
  &.-small { /* ... */ }
  &.-full { /* ... */ }
}
```

### Element Variants
```css
.shopping-card {
  & > .title { /* ... */ }
  & > .title.-small { /* ... */ }
}
```

### HTML Usage
```html
<div class='like-button -wide -disabled'>...</div>

<div class='search-form -full'>
  <input class='field' type='text'>
  <button class='button'></button>
</div>
```

---

## 4. Nested Components

### Definition
Components can contain other components. This is common in complex UIs.

### HTML Structure
```html
<div class='article-link'>
  <div class='vote-box'>
    <button class='up'></button>
    <button class='down'></button>
    <span class='count'>4</span>
  </div>
  <h3 class='title'>Article title</h3>
  <p class='meta'>Published today</p>
</div>
```

### Component Isolation Rule
**Components MUST NOT reference other components in their CSS files.**

Each component should only style itself and its own elements.

### Styling Nested Components

#### ❌ AVOID: Reaching into nested components
```css
/* In article-header.css */
.article-header {
  & > .vote-box > .up { /* ✗ avoid - referencing another component */ }
}
```

This breaks component encapsulation and creates coupling between components.

#### ✓ CORRECT: Use variants on the nested component
```html
<div class='article-header'>
  <div class='vote-box -highlight'>
    ...
  </div>
</div>
```

```css
/* In vote-box.css */
.vote-box {
  &.-highlight > .up { /* ✓ correct - variant within the component */ }
}
```

### Simplifying Nested Components
When a nested component needs specific styling in a context, create an element in the parent that mirrors the needed styles:

**HTML:**
```html
<div class='search-form'>
  <input class='input' type='text'>
  <button class='submit'></button>
</div>
```

**CSS:**
```css
/* In search-form.css */
.search-form {
  & > .submit {
    /* Define styles directly here */
    background: var(--color-primary);
    padding: var(--space-md) var(--space-lg);
    border-radius: var(--radius-md);
  }
}
```

---

## 5. Layouts

### Core Principle
Components should be **reusable in different contexts**. Avoid positioning properties within components.

### Properties to Avoid in Components
- Positioning: `position`, `top`, `left`, `right`, `bottom`
- Floats: `float`, `clear`
- Margins: `margin`
- Dimensions: `width`, `height` (with exceptions)

### Exception: Fixed Dimensions
Elements with inherently fixed dimensions are allowed:
- Avatars
- Logos
- Icons

### Define Positioning in Parent Contexts
Apply layout properties on the parent/container, not the component itself:

```css
/* In article-list.css */
.article-list {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: var(--space-lg);

  & > .article-card {
    /* Layout-specific positioning if needed */
  }
}

/* In article-card.css */
.article-card {
  /* No width, margin, or positioning */
  & > .image { /* ... */ }
  & > .title { /* ... */ }
  & > .category { /* ... */ }
}
```

In this example:
- `.article-card` has NO width, margin, or positioning internally
- `.article-list` defines how `.article-card` should be laid out

---

## 6. Helpers

### Definition
Helpers are utility classes for general-purpose overrides. Use sparingly.

### Naming Rules
- **MUST** prefix with underscore (`_`)
- Use `!important` (helpers are meant to override)
- Intentionally ugly to discourage overuse

### Examples
```css
._unmargin { margin: 0 !important; }
._center { text-align: center !important; }
._pull-left { float: left !important; }
._pull-right { float: right !important; }
```

### HTML Usage
```html
<div class='order-graphs -slim _unmargin'>
</div>
```

### Organization
- Place all helpers in a single file called `helpers.css`
- Keep the number of helpers to a minimum
- Avoid creating too many helpers

---

## 7. CSS File Structure

### One Component Per File
**CRITICAL RULE**: Each component **MUST** have its own separate CSS file.

```css
/* css/components/search-form.css */
.search-form {
  & > .button { /* ... */ }
  & > .field { /* ... */ }
  & > .label { /* ... */ }

  &.-small { /* ... */ }
  &.-wide { /* ... */ }
}
```

### File Organization
```
css/
├── variables.css          (CSS variables for colors, spacing, etc.)
├── helpers.css            (Utility classes with _ prefix)
└── components/
    ├── search-form.css    (One component)
    ├── article-card.css   (Another component)
    ├── vote-box.css       (Another component)
    └── like-button.css    (Another component)
```

### Component File Rules
- One component per file
- File name matches component name (e.g., `search-form.css` for `.search-form`)
- **MUST NOT** include styles for other components in the file
- Only include styles for the component itself, its elements, and its variants

### Nesting Depth Limit
**RULE: Use no more than 1 level of nesting**

This prevents getting lost in deeply nested selectors.

#### ❌ AVOID: 3 levels of nesting
```css
/* ✗ Avoid: 3 levels of nesting */
.image-frame {
  & > .description {
    /* ... */

    & > .icon {
      /* ... */
    }
  }
}
```

#### ✓ CORRECT: 2 levels maximum
```css
/* ✓ Better: 2 levels */
.image-frame {
  & > .description { /* ... */ }
  & > .description > .icon { /* ... */ }
}
```

---

## 8. Common Pitfalls

### Bleeding Through Nested Components

#### The Problem
When nested components share element names, styles can bleed through:

```html
<article class='article-link'>
  <div class='vote-box'>
    <button class='up'></button>
    <button class='down'></button>
    <span class='count'>4</span>
  </div>

  <h3 class='title'>Article title</h3>
  <p class='count'>3 votes</p>
</article>
```

```css
.article-link {
  & > .title { /* ... */ }
  & > .count { /* ... (!!!) */ }
}

.vote-box {
  & > .up { /* ... */ }
  & > .down { /* ... */ }
  & > .count { /* ... */ }
}
```

#### The Solution
Without the `>` child selector, `.article-link .count` would also apply to `.vote-box .count`. **Always use child selectors** to prevent this.

---

## 9. Quick Reference

### Naming Patterns

| Type | Pattern | Example | CSS |
|------|---------|---------|-----|
| Component | 2+ words, dashes | `search-form` | `.search-form` |
| Element | 1 word, no separators | `field` | `.search-form > .field` |
| Multi-word element | Concatenated | `firstname` | `.profile > .firstname` |
| Variant | Dash prefix | `-wide` | `.search-form.-wide` |
| Helper | Underscore prefix | `_unmargin` | `._unmargin` |

### CSS Structure Template

```css
/* components/component-name.css */
.component-name {
  /* Component base styles */
  background: var(--color-primary);
  padding: var(--space-md);

  & > .element {
    /* Element styles */
    color: var(--color-gray-900);
  }

  & > .element > .child {
    /* Nested element styles (max 2 levels) */
  }

  & > .anotherelement {
    /* Another element */
  }

  &.-variant {
    /* Variant styles */
    background: var(--color-secondary);
  }

  &.-another-variant {
    /* Another variant */

    & > .element {
      /* Element styles within variant context */
    }
  }
}
```

### Checklist for Writing RSCSS

- [ ] Component names have 2+ words with dashes
- [ ] Element names are single words (or concatenated)
- [ ] Using `>` child selectors for elements
- [ ] Variants use dash prefix (`-`)
- [ ] No positioning properties in components (except fixed dimensions)
- [ ] Layout properties defined in parent contexts
- [ ] Nesting no more than 1 level deep
- [ ] **Each component in its own file**
- [ ] **Components do NOT reference other components**
- [ ] Not reaching into nested components (use variants instead)
- [ ] Helpers use underscore prefix and are used sparingly
- [ ] **Using CSS variables for colors, spacing, and reusable values**
- [ ] **Variable names are broad and reusable, not specific**

---

## 10. Comparison with Other Methodologies

### RSCSS vs BEM

#### BEM
```html
<form class='site-search site-search--full'>
  <input class='site-search__field' type='text'>
  <button class='site-search__button'></button>
</form>
```

#### RSCSS
```html
<form class='site-search -full'>
  <input class='field' type='text'>
  <button class='button'></button>
</form>
```

### Terminology Mapping

| RSCSS | BEM | SMACSS |
|-------|-----|--------|
| Component | Block | Module |
| Element | Element | Sub-Component |
| Layout | ? | Layout |
| Variant | Modifier | Sub-Module & State |

---

## Summary

**Use pure CSS** with native CSS nesting (no preprocessors)

**Extract design tokens** to CSS variables with broad, reusable names

**Think in components** named with 2+ words (`.screenshot-image`)

**Each component in its own file** and components never reference other components

**Components have elements** named with 1 word (`.blog-post > .title`)

**Name variants** with a dash prefix (`.shop-banner.-with-icon`)

**Components can nest** but don't reach into them (use variants)

**Keep helpers minimal** and prefix with underscore

**Maximum 1 level of nesting** to keep CSS readable
