# Jelika - AI Assistant Development Guide

**Project:** Jelika - AI-powered CMS for social network content
**Status:** Pivoted from a video-production tool (see "History" below)

---

## Quick Start for AI Assistants

This guide helps you understand Jelika and assist with development efficiently.

### Essential Reading Order

1. **This file first** - Overview and development approach (10 min)
2. **[database/schema.sql](database/schema.sql)** + `database/migrations/009`-`011` - Database structure
3. **[docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md)** - UI design system

> ⚠️ **`docs/` is stale.** Everything under `docs/` except the design system still
> describes the old script-to-video product. Do not treat it as a specification.
> The database schema and the code are the source of truth.

### Project Context

**What it does:** A CMS for planning, generating, and scheduling social media content.

**Core workflow:**
1. User connects channels (Instagram, TikTok, LinkedIn, X, …)
2. User writes a post — one shared caption, plus per-channel overrides
3. Media is attached, either uploaded or AI-generated from an avatar + environment
4. Post is scheduled; n8n publishes to each channel and writes the result back

**Tech stack:** Vue 3, Supabase (PostgreSQL + Auth + Storage + Realtime), n8n automation, TailwindCSS

### History: what pivoted

The project began as "UCG Studio", a script-to-video tool. The name is gone and the
domain has moved to social content management. Two things survive from that era:

- **Kept and central:** the AI generation stack — `avatars`, `avatar_wardrobes`,
  `environments`, and `n8n_jobs`. These now produce the *media attached to posts*.
- **Legacy, still present but unused by the CMS:** the `shots` and `exports` tables
  and the video-production columns on `projects`. They were deliberately left in
  place rather than dropped. `projects` is reused as **campaigns** — a grouping for
  posts (the sidebar already labels it "Campaigns").

---

## Project Structure

```
/workspace/workspace/jelika/
├── frontend/                 # Vue 3 application
│   ├── src/
│   │   ├── components/      # Reusable Vue components
│   │   │   ├── auth/        # ✅ Login, Signup, Password Reset
│   │   │   ├── common/      # ✅ AppHeader
│   │   │   ├── dashboard/   # Project cards, stats widgets
│   │   │   ├── project/     # Project creation, settings
│   │   │   ├── content/     # ✅ Channel variant editor (core feature)
│   │   │   └── production/  # Legacy video production components
│   │   ├── views/           # Route pages
│   │   │   ├── auth/        # ✅ Auth pages
│   │   │   ├── dashboard/   # ✅ Dashboard
│   │   │   ├── project/     # Project detail view
│   │   │   ├── settings/    # User settings
│   │   │   └── admin/       # Admin dashboard
│   │   ├── stores/          # Pinia state management
│   │   │   └── auth.js      # ✅ Authentication store
│   │   ├── composables/     # Reusable composition functions
│   │   ├── utils/           # Helper functions
│   │   ├── lib/
│   │   │   └── supabase.js  # ✅ Supabase client
│   │   ├── router/
│   │   │   └── index.js     # ✅ Vue Router config
│   │   └── assets/
│   │       └── styles/
│   │           └── main.css # Tailwind + custom styles
│   ├── .env.local           # ✅ Environment variables
│   ├── package.json         # ✅ Dependencies
│   ├── vite.config.js       # ✅ Vite configuration
│   └── tailwind.config.js   # ✅ TailwindCSS config
├── database/
│   └── schema.sql           # ✅ Complete PostgreSQL schema
├── deployment/
│   ├── docker-compose.yml   # ✅ Production deployment
│   └── .env.example         # Environment template
├── docs/                    # Documentation
│   ├── README.md            # Complete technical specification
│   ├── DESIGN_SYSTEM.md     # UI design system
│   ├── COMPONENT_LIBRARY.md # Component reference
│   ├── PROGRESS.md          # Development tracker
│   ├── GETTING_STARTED.md   # Setup guide
│   ├── QUICK_FIX_GUIDE.md   # Common issues
│   └── START_HERE.md        # Quick start
├── CLAUDE.md                # This file
└── README.md                # Project overview
```

---

## What's Already Built (Phase 1 ✅)

### Completed Features
- ✅ Vue 3 project with Vite
- ✅ Supabase client configuration
- ✅ Authentication system (email + Google OAuth)
- ✅ Protected routes with auth guards
- ✅ Dashboard with project list
- ✅ User profile header with credit balance
- ✅ Complete design system (TailwindCSS)
- ✅ Production build verified

### File References
- Auth Store: [frontend/src/stores/auth.js](frontend/src/stores/auth.js)
- Router: [frontend/src/router/index.js](frontend/src/router/index.js)
- Dashboard: [frontend/src/views/dashboard/DashboardView.vue](frontend/src/views/dashboard/DashboardView.vue)
- App Header: [frontend/src/components/common/AppHeader.vue](frontend/src/components/common/AppHeader.vue)

---

## Current State & Next Steps

### Built

- Auth (email + Google OAuth), protected routes, admin roles
- Avatar library, environment creation/editing with AI generation via n8n
- Credits, billing, admin settings
- **Social CMS:** channels, posts, per-channel variants, media, content calendar

### Frontend map for the CMS

- Store: [frontend/src/stores/posts.js](frontend/src/stores/posts.js) — posts, variants, media, realtime
- Store: [frontend/src/stores/socialAccounts.js](frontend/src/stores/socialAccounts.js)
- Helper: [frontend/src/lib/platforms.js](frontend/src/lib/platforms.js) — platform list, caption limits, status badges
- Calendar: [frontend/src/views/content/ContentCalendarView.vue](frontend/src/views/content/ContentCalendarView.vue)
- Editor: [frontend/src/views/content/PostEditorView.vue](frontend/src/views/content/PostEditorView.vue)
- Per-channel captions: [frontend/src/components/content/ChannelVariantEditor.vue](frontend/src/components/content/ChannelVariantEditor.vue)
- Channels: [frontend/src/views/accounts/SocialAccountsView.vue](frontend/src/views/accounts/SocialAccountsView.vue)

### Not built yet

1. **Publishing pipeline** — n8n workflows for `post_publish`. The schema is ready
   (`post_variants.external_post_id`/`external_url`/`error_message`, and the
   `post_publish` workflow type). Nothing calls them yet.
2. **Real OAuth channel connection** — channels are added by hand today. The
   `credential_ref` column is the intended hook.
3. **Attaching generated media to a post** — `posts.attachMedia()` exists in the
   store, but no UI wires environment generation output into a post.
4. **Approval flow** — `needs_review` / `approved` statuses exist and are settable,
   but there is no reviewer inbox.
5. **Analytics** — no engagement metrics are collected.

## Key Technical Patterns

### Supabase Client Usage

```javascript
// lib/supabase.js
import { createClient } from '@supabase/supabase-js'

export const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
)
```

### Real-time Subscriptions

```javascript
// In Vue component
const channel = supabase
  .channel('posts-realtime')
  .on('postgres_changes', {
    event: 'UPDATE',
    schema: 'public',
    table: 'posts',
    filter: `user_id=eq.${userId}`
  }, (payload) => {
    updatePostInState(payload.new)
  })
  .subscribe()

// Cleanup
onUnmounted(() => channel.unsubscribe())
```

### n8n Webhook Calls

```javascript
// composables/useN8n.js
export function useN8n() {
  const baseUrl = import.meta.env.VITE_N8N_WEBHOOK_URL
  const apiKey = import.meta.env.VITE_N8N_API_KEY

  async function generatePostMedia(postId, prompt, environmentId) {
    const response = await fetch(`${baseUrl}/webhook/post-media`, {
      method: 'POST',
      headers: {
        'X-API-Key': apiKey,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ post_id: postId, prompt, environment_id: environmentId })
    })

    if (!response.ok) throw new Error('Post media generation failed')
    return response.json()
  }

  return { scriptBreakdown }
}
```

### Credit Deduction Flow

```
1. User clicks "Generate"
2. Check: user has enough credits?
3. If yes: Immediately deduct credits (UPDATE profiles)
4. Database trigger: Insert credit_transaction record
5. Database trigger: Update user balance
6. Call the n8n webhook (media generation)
7. n8n returns base64 media
8. Upload to Supabase Storage
9. Insert a post_media row with the file URL
10. If failed: Trigger auto-refunds credits
```

---

## Database Schema Overview

### Key Tables

**Social CMS core** (migrations 009-011):

```sql
-- Channels the user publishes to. No OAuth token is stored here: the client
-- reads this table under RLS, so credentials live in n8n and are referenced
-- by credential_ref.
social_accounts (
  id, user_id, platform, handle, display_name,
  external_account_id, credential_ref, is_active
)

-- One piece of content, channel-agnostic. title is internal (calendar label),
-- never published.
posts (
  id, user_id, title, body, hashtags[], status,
  scheduled_for, published_at,
  project_id,                    -- campaign grouping
  avatar_id, environment_id      -- generation context
)

-- The per-channel version that actually publishes. NULL override = inherit
-- from the parent post. Carries a denormalised user_id so RLS avoids a join.
post_variants (
  id, post_id, social_account_id, user_id,
  body_override, hashtags_override, scheduled_for_override,
  status, external_post_id, external_url, published_at, error_message
)

-- Media on a post, uploaded or generated. Generated rows keep provenance back
-- to the environment/avatar/job that produced them.
post_media (
  id, post_id, user_id, kind, source, file_url, position,
  environment_id, avatar_id, n8n_job_id
)
```

**Generation stack** (pre-existing, still central):

```sql
avatars (id, user_id, name, reference_photo_url, physical_specs JSONB, ...)
environments (id, user_id, name, reference_image_url, result_images JSONB[], active_result_index, ...)
n8n_jobs (id, user_id, workflow_type, status, environment_id, avatar_id, post_id, ...)
```

**Accounts and money:** `profiles`, `credit_transactions`, `payment_transactions`, `admin_settings`.

**Legacy, unused by the CMS:** `shots`, `exports`.

### RPCs worth knowing

- `get_content_calendar(range_start, range_end)` — posts in a window with their
  channels and media count folded into one row. The calendar renders from this.
- `schedule_post(target_post_id, publish_at)` — moves the post *and* every one of
  its variants to `scheduled` atomically, so a scheduled post can never show
  channels stranded in draft. Raises if the post has no channels.

### Trigger gotcha (fixed in migration 011)

`update_updated_at_column()` used to assign `NEW.updated_by = auth.uid()`
unconditionally. That broke every `UPDATE` on tables without an `updated_by`
column (`n8n_jobs`), and every service-role write to tables where it is `NOT NULL`
(n8n writing results back to `environments`). There are now two functions:

- `update_updated_at_column()` — timestamp only; for `n8n_jobs`, `post_variants`, `post_media`
- `set_updated_audit_columns()` — timestamp + `updated_by`, using
  `COALESCE(auth.uid(), NEW.updated_by)` so service-role writes keep the last human editor

**Any new table with an `updated_by` column must use `set_updated_audit_columns()`.**

**Important:** All tables have Row Level Security (RLS) enabled. Users only see their own data.

---

## Design System

### Colors
```javascript
// tailwind.config.js
colors: {
  primary: {
    DEFAULT: '#1313EC',  // Blue (9 shades: 50-900)
  },
  success: {
    DEFAULT: '#22D34E',  // Green (9 shades: 50-900)
  },
  error: {
    DEFAULT: '#F04438',  // Red (9 shades: 50-900)
  },
  warning: {
    DEFAULT: '#F79009',  // Orange (9 shades: 50-900)
  },
  neutral: {
    50: '#F8F8F8',       // 10 shades: 50-900
    900: '#111118',
  }
}
```

### Pre-built Component Classes
```css
/* Buttons */
.btn-primary         /* Primary action button */
.btn-secondary       /* Secondary action button */
.btn-ghost           /* Minimal button */
.btn-danger          /* Destructive action */

/* Inputs */
.input-field         /* Standard text input */
.input-label         /* Form label */
.input-error         /* Error message */

/* Cards */
.card                /* Basic card container */
.card-hover          /* Clickable card with hover */
.card-interactive    /* Card with press feedback */

/* Badges */
.badge-primary       /* Primary badge */
.status-generating   /* Generating status with animation */
.status-completed    /* Completed status */
.status-error        /* Error status */
```

See [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md) for complete reference.

---

## Development Guidelines

### Vue Component Structure

```vue
<script setup>
// 1. Imports
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'

// 2. State
const isLoading = ref(false)
const error = ref(null)

// 3. Computed
const hasError = computed(() => error.value !== null)

// 4. Methods
async function fetchData() {
  isLoading.value = true
  try {
    const { data, error: fetchError } = await supabase
      .from('projects')
      .select('*')

    if (fetchError) throw fetchError
    return data
  } catch (err) {
    error.value = err.message
  } finally {
    isLoading.value = false
  }
}

// 5. Lifecycle
onMounted(() => fetchData())
</script>

<template>
  <div class="container">
    <!-- Use semantic HTML + Tailwind classes -->
  </div>
</template>
```

### Error Handling

```javascript
try {
  const { data, error } = await supabase.from('projects').select('*')
  if (error) throw error
  return data
} catch (error) {
  console.error('Failed to fetch projects:', error)
  // TODO: Add Sentry integration
  showToast('Failed to load projects. Please try again.', 'error')
}
```

### Naming Conventions
- **Components:** PascalCase (ProductionTable.vue)
- **Files:** kebab-case (use-credits.js)
- **Variables:** camelCase (creditBalance)
- **Constants:** UPPER_SNAKE_CASE (MAX_FILE_SIZE)
- **Database:** snake_case (credit_balance)

---

## Critical Rules

### Security
- ✅ All database queries use RLS - users only see their own data
- ✅ Never expose API keys client-side - use environment variables
- ✅ Validate all inputs - both client and server-side
- ✅ Use Supabase Auth exclusively

### Performance
- ✅ Use Supabase Realtime - don't poll for updates
- ✅ Lazy load route components
- ✅ Cache API responses in Pinia stores

### UX Requirements
- ✅ Show loading states for every async operation
- ✅ Display errors gracefully with toast notifications
- ✅ Confirm destructive actions with modals
- ✅ Mobile responsive with Tailwind breakpoints

### Business Logic
- ✅ Credits deducted immediately before generation
- ✅ Automatic refunds on failure via database trigger
- ✅ Storage quota checks before upload (1GB per user)

---

## Common Tasks

### Adding a New Page

1. Create view component in `src/views/[feature]/`
2. Add route in `src/router/index.js`
3. Add navigation link if needed

### Creating a New API Composable

```javascript
// src/composables/useProjects.js
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export function useProjects() {
  const projects = ref([])
  const isLoading = ref(false)

  async function fetchProjects() {
    isLoading.value = true
    const { data, error } = await supabase
      .from('projects')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) throw error
    projects.value = data
    isLoading.value = false
  }

  return {
    projects,
    isLoading,
    fetchProjects
  }
}
```

### Adding Real-time Updates

```javascript
// In component setup
const subscription = supabase
  .channel('table-changes')
  .on('postgres_changes', {
    event: '*',
    schema: 'public',
    table: 'posts',
    filter: `user_id=eq.${userId}`
  }, handleUpdate)
  .subscribe()

onUnmounted(() => subscription.unsubscribe())
```

---

## Troubleshooting

### Common Issues

**Build fails with Tailwind error**
- Ensure Tailwind v3 is installed: `npm install -D tailwindcss@3`

**"relation 'profiles' does not exist" error**
- See [docs/QUICK_FIX_GUIDE.md](docs/QUICK_FIX_GUIDE.md)

**Supabase RLS blocking queries**
- Check that the user is authenticated
- Verify RLS policies allow the operation
- Review policies in Supabase Dashboard > Authentication > Policies

**Real-time not working**
- Enable Realtime on the table in Supabase Dashboard > Database > Replication
- Check RLS policies allow SELECT on the table

---

## Testing Checklist

Before considering a feature complete:

- [ ] Happy path works (successful flow)
- [ ] Error states handled (API failures, network errors)
- [ ] Loading states shown (spinners, skeletons)
- [ ] Empty states displayed (no data)
- [ ] Mobile responsive (test at 375px, 768px, 1440px)
- [ ] Real-time updates work (Supabase subscriptions)
- [ ] Credits deduct/refund correctly
- [ ] RLS policies enforced (users can't see others' data)

---

## Documentation References

### Quick Guides
- [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md) - Setup instructions
- [docs/PROGRESS.md](docs/PROGRESS.md) - Development tracker
- [docs/START_HERE.md](docs/START_HERE.md) - Quick start for developers

### Technical Specs
- [docs/README.md](docs/README.md) - Complete specification (2100+ lines)
- [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md) - UI design system
- [docs/COMPONENT_LIBRARY.md](docs/COMPONENT_LIBRARY.md) - Component reference
- [database/schema.sql](database/schema.sql) - Database structure

### Deployment
- [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) - Production deployment
- [deployment/docker-compose.yml](deployment/docker-compose.yml) - Docker config

---

## Pro Tips

1. **Read relevant docs first** - Don't guess, the specs are comprehensive
2. **Follow the design system** - Use pre-built classes from main.css
3. **Build iteratively** - Complete one feature before starting the next
4. **Test as you go** - Run the app after each component
5. **Reference the schema** - Database is the source of truth
6. **Use Supabase Realtime** - Don't poll, subscribe to changes
7. **Keep components small** - Under 200 lines each
8. **Leverage RLS** - Let the database handle permissions

---

## Success Criteria

**MVP is ready when:**
- [ ] Users can connect channels and see them in the picker
- [x] Posts can be created with a shared caption and per-channel overrides
- [x] Content calendar shows scheduled posts across channels
- [x] Scheduling moves the post and every variant atomically
- [ ] n8n publishes to each channel and writes back the permalink
- [ ] Failed channels surface the error and can be retried
- [ ] Generated media from an environment can be attached to a post
- [ ] Credits deduct and refund correctly
- [ ] Mobile layout doesn't break
- [ ] No errors in browser console

## Ready to Build!

The next meaningful piece is the **publishing pipeline**: n8n workflows that read
`post_variants`, publish to each platform, and write `external_url` or
`error_message` back. The schema and the UI for it already exist.

**Last Updated:** August 31, 2026
**Next Milestone:** Publishing pipeline (n8n → channels → write-back)
