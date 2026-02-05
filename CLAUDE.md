# UCG Studio - AI Assistant Development Guide

**Project:** UCG Studio - AI-Powered Video Production Platform
**Deadline:** February 14, 2026 (MVP)
**Status:** Phase 1 Complete (Authentication ✅)

---

## Quick Start for AI Assistants

This guide helps you understand UCG Studio and assist with development efficiently.

### Essential Reading Order

1. **This file first** - Overview and development approach (10 min)
2. **[README.md](README.md)** - Project overview and getting started (5 min)
3. **[docs/README.md](docs/README.md)** - Complete technical specification (as needed)
4. **[database/schema.sql](database/schema.sql)** - Database structure (when working with data)

### Project Context

**What it does:** Helps creators turn scripts into professional short-form videos using AI

**Core workflow:**
1. User pastes script → AI breaks it into segments
2. Each segment gets 3 camera angle options
3. User generates audio (ElevenLabs) + video (Google Veo 3)
4. Export organized clips ready for editing

**Tech stack:** Vue 3, Supabase (PostgreSQL + Auth + Storage + Realtime), n8n automation, TailwindCSS

---

## Project Structure

```
/workspace/workspace/ucg-studio/
├── frontend/                 # Vue 3 application
│   ├── src/
│   │   ├── components/      # Reusable Vue components
│   │   │   ├── auth/        # ✅ Login, Signup, Password Reset
│   │   │   ├── common/      # ✅ AppHeader
│   │   │   ├── dashboard/   # Project cards, stats widgets
│   │   │   ├── project/     # Project creation, settings
│   │   │   └── production/  # Production table (core feature)
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

## Next Phase: Core Workflow (In Progress)

### Immediate Priorities

1. **Project Creation Flow**
   - Create modal component with multi-step form
   - Fields: name, script, AI budget (20-100%), aspect ratio, resolution, language
   - Integrate n8n webhook for script breakdown
   - Save project to Supabase

2. **Production Table (Most Complex Feature)**
   - Data table showing all shots
   - Columns: checkbox, shot#, duration, script text, prompt selector, generate button, preview
   - Inline editing of script text
   - Prompt selector dropdown (3 alternatives per shot)
   - Generation buttons with status indicators
   - Real-time updates via Supabase Realtime

3. **Audio/Video Generation**
   - Credit deduction before generation
   - n8n webhook calls (parallel audio + video)
   - Upload returned base64 media to Supabase Storage
   - Update shot records with file URLs
   - Handle failures with automatic credit refund

4. **Export System**
   - Client-side ZIP creation using JSZip
   - File naming: shot_01_video.mp4, shot_01_audio.mp3
   - Download trigger

For detailed requirements, see [docs/README.md](docs/README.md)

---

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
  .channel('shots-realtime')
  .on('postgres_changes', {
    event: 'UPDATE',
    schema: 'public',
    table: 'shots',
    filter: `project_id=eq.${projectId}`
  }, (payload) => {
    updateShotInState(payload.new)
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

  async function scriptBreakdown(projectId, script, aiBudget) {
    const response = await fetch(`${baseUrl}/webhook/script-breakdown`, {
      method: 'POST',
      headers: {
        'X-API-Key': apiKey,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ project_id: projectId, script, ai_budget_percentage: aiBudget })
    })

    if (!response.ok) throw new Error('Script breakdown failed')
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
6. Call n8n webhooks (audio + video)
7. n8n returns base64 media
8. Upload to Supabase Storage
9. Update shot with file URLs
10. If failed: Trigger auto-refunds credits
```

---

## Database Schema Overview

### Key Tables

```sql
-- User data
profiles (
  id, full_name, email, credit_balance,
  elevenlabs_api_key, role, status, total_storage_used
)

-- Projects
projects (
  id, user_id, name, slug, script, status,
  ai_budget_percentage, target_aspect_ratio, target_resolution,
  total_shots, total_credits_used
)

-- Video segments
shots (
  id, project_id, shot_number, script_text, duration_seconds,
  ai_prompt_1, ai_prompt_2, ai_prompt_3, selected_prompt,
  shot_category_1, shot_category_2, shot_category_3,
  generation_status, audio_file_url, video_file_url,
  voice_settings JSONB
)

-- Credits
credit_transactions (
  user_id, transaction_type, amount,
  previous_balance, new_balance, reason
)

-- Payments
payment_transactions (
  user_id, payment_provider, payment_amount_usd,
  credits_purchased, payment_status
)
```

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
    table: 'shots',
    filter: `project_id=eq.${projectId}`
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
- [ ] Users can create projects with script breakdown
- [ ] Production table displays all shots with 3 prompt options
- [ ] Audio + video generation works end-to-end
- [ ] Real-time updates show generation progress
- [ ] Credits deduct and refund correctly
- [ ] Export downloads ZIP with numbered files
- [ ] Mobile layout doesn't break
- [ ] No errors in browser console

---

## Ready to Build!

Start with the Project Creation modal, then tackle the Production Table (the core feature).

For questions, consult [docs/README.md](docs/README.md) for detailed specifications.

**Last Updated:** January 20, 2026
**Current Phase:** 1 of 4 (Foundation Complete ✅)
**Next Milestone:** Core workflow (Project creation + Production table)
