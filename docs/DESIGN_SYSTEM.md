# UCG Studio - Design System v1.0

Complete design specifications and UI component library for the UCG AI video production platform.

---

## 🎨 Color Palette

### Primary Colors

**Primary Blue** - Brand & Main Actions
- `primary-50`: `#E8E8FD` - Lightest tint
- `primary-100`: `#D1D1FB`
- `primary-500`: `#1313EC` - **DEFAULT** (Brand color)
- `primary-600`: `#0F0FBD` - Hover state
- `primary-700`: `#0B0B8E` - Active state
- `primary-900`: `#04042F` - Darkest

**Usage:** Primary buttons, links, focus states, brand elements

### Status Colors

**Success Green** - Valid States & Confirmations
- `success-50`: `#E9F9EE`
- `success-100`: `#D3F3DD`
- `success-500`: `#22D34E` - **DEFAULT**
- `success-700`: `#147F2F`

**Usage:** Success messages, completed states, positive indicators

**Error Red** - Errors & Destructive Actions
- `error-50`: `#FEE9E7`
- `error-100`: `#FDD3CF`
- `error-500`: `#F04438` - **DEFAULT**
- `error-700`: `#902922`

**Usage:** Error messages, delete buttons, failed states

**Warning Orange** - Caution & In-Progress
- `warning-50`: `#FEF3E7`
- `warning-100`: `#FDE7CF`
- `warning-500`: `#F79009` - **DEFAULT**
- `warning-700`: `#945605`

**Usage:** Warning messages, generating states, attention needed

### Neutral Colors

**Neutral Gray** - Text & Backgrounds
- `neutral-50`: `#F8F8F8` - Page background
- `neutral-100`: `#F0F0F0` - Subtle backgrounds
- `neutral-200`: `#E0E0E0` - Borders
- `neutral-400`: `#A0A0A0` - Placeholder text
- `neutral-600`: `#585858` - Secondary text
- `neutral-900`: `#111118` - Primary text

---

## ✍️ Typography

### Font Family
**Primary:** Inter (400, 500, 600, 700, 900)

```css
font-family: 'Inter', system-ui, -apple-system, sans-serif;
```

### Type Scale

| Class | Size | Line Height | Weight | Usage |
|-------|------|-------------|--------|-------|
| `text-xs` | 12px | 16px | 400 | Small captions, metadata |
| `text-sm` | 14px | 20px | 400 | Body text (small), labels |
| `text-base` | 16px | 24px | 400 | Body text (default) |
| `text-lg` | 18px | 28px | 500 | Emphasized text |
| `text-xl` | 20px | 28px | 600 | Section titles |
| `text-2xl` | 24px | 32px | 700 | Page headings |
| `text-3xl` | 30px | 36px | 700 | Large headings |
| `text-4xl` | 36px | 40px | 900 | Hero display text |

### Usage Examples

```vue
<!-- Page Title -->
<h1 class="text-4xl font-black text-neutral-900">UCG Studio</h1>

<!-- Section Heading -->
<h2 class="text-2xl font-bold text-neutral-900">Your Projects</h2>

<!-- Body Text -->
<p class="text-base text-neutral-700">Welcome to UCG Studio...</p>

<!-- Small Text -->
<span class="text-sm text-neutral-500">Last updated 2 hours ago</span>

<!-- Metadata -->
<span class="text-xs text-neutral-400">Created Jan 20, 2026</span>
```

---

## 🧩 UI Components

### Buttons

#### Primary Button
```vue
<button class="btn-primary">
  Generate Video
</button>
```
**Use for:** Main actions, CTAs, form submissions

#### Secondary Button
```vue
<button class="btn-secondary">
  Cancel
</button>
```
**Use for:** Secondary actions, alternative options

#### Ghost Button
```vue
<button class="btn-ghost">
  View Details
</button>
```
**Use for:** Tertiary actions, minimal emphasis

#### Danger Button
```vue
<button class="btn-danger">
  Delete Project
</button>
```
**Use for:** Destructive actions only

#### Size Variants
```vue
<button class="btn-primary btn-sm">Small</button>
<button class="btn-primary">Medium (Default)</button>
<button class="btn-primary btn-lg">Large</button>
```

#### Button States
- **Default:** Normal appearance
- **Hover:** Darker shade + subtle shadow
- **Active:** Even darker shade
- **Disabled:** 50% opacity, no interaction
- **Focus:** Blue ring outline

---

### Input Fields

#### Text Input
```vue
<div>
  <label class="input-label">Project Name</label>
  <input
    type="text"
    class="input-field"
    placeholder="Enter project name"
  />
  <p class="input-hint">Choose a memorable name</p>
</div>
```

#### Error State
```vue
<div>
  <label class="input-label">Email</label>
  <input
    type="email"
    class="input-field error"
    placeholder="you@example.com"
  />
  <p class="input-error">Please enter a valid email</p>
</div>
```

#### Textarea
```vue
<textarea
  class="input-field h-32"
  placeholder="Enter your script..."
></textarea>
```

#### Select Dropdown
```vue
<select class="input-field">
  <option>16:9 Landscape</option>
  <option>9:16 Portrait</option>
  <option>1:1 Square</option>
</select>
```

---

### Cards

#### Basic Card
```vue
<div class="card">
  <h3 class="text-xl font-semibold mb-2">Card Title</h3>
  <p class="text-neutral-600">Card content goes here</p>
</div>
```

#### Hoverable Card
```vue
<div class="card-hover">
  <!-- Content -->
</div>
```
**Use for:** Clickable items like project cards

#### Interactive Card
```vue
<div class="card-interactive">
  <!-- Content -->
</div>
```
**Use for:** Selectable items with press feedback

---

### Badges & Status Indicators

#### Standard Badges
```vue
<span class="badge-primary">New</span>
<span class="badge-success">Active</span>
<span class="badge-error">Failed</span>
<span class="badge-warning">Pending</span>
<span class="badge-neutral">Draft</span>
```

#### Generation Status Badges
```vue
<!-- Recommended by AI -->
<span class="status-recommended">Recommended</span>

<!-- Currently generating -->
<span class="status-generating">Generating...</span>

<!-- Successfully completed -->
<span class="status-completed">Completed</span>

<!-- Generation failed -->
<span class="status-error">Error</span>

<!-- Waiting to generate -->
<span class="status-pending">Pending</span>
```

**Visual Features:**
- Emoji icons before text
- Animated pulse for "generating"
- Color-coded backgrounds

---

### Alerts & Notifications

#### Alert Variants
```vue
<!-- Informational -->
<div class="alert-info">
  <strong>Info:</strong> Your project is ready for export.
</div>

<!-- Success -->
<div class="alert-success">
  <strong>Success!</strong> Video generated successfully.
</div>

<!-- Warning -->
<div class="alert-warning">
  <strong>Warning:</strong> Low credit balance.
</div>

<!-- Error -->
<div class="alert-error">
  <strong>Error:</strong> Generation failed. Please try again.
</div>
```

---

### Loading States

#### Spinner
```vue
<div class="flex items-center gap-2">
  <span class="loading-spinner"></span>
  <span>Loading...</span>
</div>
```

#### Skeleton Loader
```vue
<div class="loading-skeleton h-4 w-32 mb-2"></div>
<div class="loading-skeleton h-20 w-full"></div>
```

---

### Progress Bar

```vue
<div class="progress-bar">
  <div class="progress-bar-fill" style="width: 74%"></div>
</div>
```

**Use for:** AI influence percentage, upload progress, generation progress

---

### Modal

```vue
<div class="modal-overlay" @click.self="closeModal">
  <div class="modal-content">
    <h2 class="text-2xl font-bold mb-4">Modal Title</h2>
    <p class="text-neutral-600 mb-6">Modal content goes here.</p>
    <div class="flex gap-3 justify-end">
      <button class="btn-secondary">Cancel</button>
      <button class="btn-primary">Confirm</button>
    </div>
  </div>
</div>
```

---

### Dropdown Menu

```vue
<div class="relative">
  <button @click="toggleMenu">Menu</button>

  <div v-if="showMenu" class="dropdown-menu">
    <button class="dropdown-item">Edit</button>
    <button class="dropdown-item">Duplicate</button>
    <div class="border-t border-neutral-200 my-1"></div>
    <button class="dropdown-item text-error-600">Delete</button>
  </div>
</div>
```

---

### Table

```vue
<table class="table">
  <thead>
    <tr>
      <th>Shot #</th>
      <th>Script</th>
      <th>Status</th>
      <th>Actions</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>01</td>
      <td>Opening scene with sunrise...</td>
      <td><span class="status-completed">Completed</span></td>
      <td>
        <button class="btn-ghost btn-sm">View</button>
      </td>
    </tr>
  </tbody>
</table>
```

---

## 📐 Spacing & Layout

### Spacing Scale
- `0` = 0px
- `1` = 4px (0.25rem)
- `2` = 8px (0.5rem)
- `3` = 12px (0.75rem)
- `4` = 16px (1rem)
- `6` = 24px (1.5rem)
- `8` = 32px (2rem)
- `12` = 48px (3rem)

### Container Widths
```vue
<!-- Full width with padding -->
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
  <!-- Content -->
</div>
```

### Grid Layouts
```vue
<!-- 3-column grid -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  <!-- Items -->
</div>
```

---

## 🎭 Shadows & Elevation

### Shadow Scale
- `shadow-sm` - Subtle elevation
- `shadow` - Default cards
- `shadow-md` - Hover states
- `shadow-lg` - Modals, dropdowns
- `shadow-card` - Custom card shadow
- `shadow-card-hover` - Card hover state

---

## 🔲 Border Radius

- `rounded-sm` - 6px - Small elements
- `rounded` / `rounded-md` - 8px - Default (buttons, inputs)
- `rounded-lg` - 12px - Cards, modals
- `rounded-xl` - 16px - Large containers
- `rounded-full` - 9999px - Circles, pills

---

## 🎬 Animations

### Transitions
All interactive elements have **200ms** transition duration by default.

### Custom Animations

**Fade In**
```vue
<div class="animate-fade-in">
  Content fades in from below
</div>
```

**Slide In**
```vue
<div class="animate-slide-in">
  Content slides in from right
</div>
```

**Shimmer (Loading)**
```vue
<div class="animate-shimmer">
  Shimmer effect
</div>
```

---

## 🔍 Focus States

All interactive elements have focus rings:
```vue
<button class="focus-ring">Accessible Button</button>
```

**Keyboard Navigation:**
- Tab through interactive elements
- Blue ring indicates focus
- 2px offset for clarity

---

## 📱 Responsive Breakpoints

```css
/* Mobile first approach */
sm: 640px   /* Small tablets */
md: 768px   /* Tablets */
lg: 1024px  /* Laptops */
xl: 1280px  /* Desktops */
```

### Usage
```vue
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3">
  <!-- Responsive grid -->
</div>
```

---

## ♿ Accessibility

### Guidelines
1. **Color Contrast:** All text meets WCAG AA standards
2. **Focus Indicators:** Visible on all interactive elements
3. **Keyboard Navigation:** Full keyboard support
4. **ARIA Labels:** Use on icon-only buttons
5. **Alt Text:** Required for all images

### Example
```vue
<button
  class="btn-primary"
  aria-label="Generate video from script"
>
  Generate
</button>
```

---

## 🎨 Component States

### Standard States (All Interactive Elements)

| State | Visual Change | Trigger |
|-------|--------------|---------|
| Default | Base appearance | - |
| Hover | Darker shade, shadow | Mouse over |
| Active | Darkest shade | Mouse down |
| Focus | Blue ring outline | Keyboard focus |
| Disabled | 50% opacity | Disabled attribute |

---

## 🎯 AI-Specific Components

### Generation Badge States

```vue
<!-- Before generation -->
<span class="status-recommended">✨ Recommended</span>

<!-- During generation -->
<span class="status-generating">⚡ Generating...</span>

<!-- After success -->
<span class="status-completed">✓ Completed</span>

<!-- After failure -->
<span class="status-error">⚠ Error</span>
```

### Prompt Alternative Selector
```vue
<div class="flex gap-2">
  <button class="btn-secondary">Variant A</button>
  <button class="btn-secondary">Variant B</button>
  <button class="btn-secondary">Variant C</button>
</div>
```

### AI Influence Slider
```vue
<div>
  <label class="input-label">AI Budget: 74%</label>
  <input
    type="range"
    min="20"
    max="100"
    value="74"
    class="w-full"
  />
  <div class="flex justify-between text-xs text-neutral-500 mt-1">
    <span>Strict Style</span>
    <span>Creative Freedom</span>
  </div>
</div>
```

---

## 📦 Icon System

### Icon Sources
- **Heroicons** (recommended)
- **Lucide Icons** (alternative)
- SVG inline for custom icons

### Icon Sizes
- `w-4 h-4` (16px) - Small, inline with text
- `w-5 h-5` (20px) - Default
- `w-6 h-6` (24px) - Large buttons
- `w-8 h-8` (32px) - Feature icons

---

## 🚀 Quick Reference

### Common Patterns

**Form Field**
```vue
<div>
  <label class="input-label">Label</label>
  <input class="input-field" />
  <p class="input-hint">Helper text</p>
</div>
```

**Stat Card**
```vue
<div class="card">
  <p class="text-sm text-neutral-500">Total Projects</p>
  <p class="text-3xl font-bold text-neutral-900">24</p>
</div>
```

**Action Buttons**
```vue
<div class="flex gap-3">
  <button class="btn-secondary">Cancel</button>
  <button class="btn-primary">Save</button>
</div>
```

---

## 📚 Resources

- **Tailwind Docs:** https://tailwindcss.com/docs
- **Inter Font:** https://fonts.google.com/specimen/Inter
- **Heroicons:** https://heroicons.com
- **Color Contrast Checker:** https://webaim.org/resources/contrastchecker

---

**Design System Version:** 1.0
**Last Updated:** January 20, 2026
**Status:** Production Ready ✅
