# UCG Studio - Development Guide for Claude Code

**Project:** UCG Studio - AI-Powered Video Production Platform  
**Deadline:** February 14, 2026 (MVP)  
**Developer:** Solo (you + Claude Code)  
**Status:** Starting from zero

---

## 🎯 Project Mission

Build an AI-powered platform that helps creators produce consistent short-form video content by:
1. Breaking scripts into optimized video segments
2. Generating audio voiceovers (ElevenLabs)
3. Generating AI video clips (Google Veo 3)
4. Managing production workflow in an intuitive table interface
5. Exporting organized, numbered clips ready for editing

---

## 📚 Available Documentation

You have access to these specification files:

1. **README.md** - Complete project specification (76KB)
2. **database/schema.sql** - Full PostgreSQL schema with RLS
3. **deployment/docker-compose.yml** - Production deployment config
4. **docs/FILE_STRUCTURE.md** - Recommended file organization
5. **docs/DEPLOYMENT_GUIDE.md** - Step-by-step deployment
6. **docs/QUICK_START.md** - Fast-track development guide

**Read these files FIRST before writing any code.**

---

## 🏗️ Technology Stack

### Frontend
```yaml
framework: Vue 3
build_tool: Vite
styling: TailwindCSS
state_management: Pinia
routing: Vue Router
client_sdk: @supabase/supabase-js
```

### Backend (Serverless)
```yaml
database: Supabase (PostgreSQL 15)
authentication: Supabase Auth (Email + Google OAuth)
storage: Supabase Storage (3 buckets)
realtime: Supabase Realtime (WebSocket subscriptions)
automation: n8n (self-hosted workflows)
```

### Infrastructure
```yaml
hosting: DigitalOcean (Docker)
containerization: Docker Compose
reverse_proxy: Nginx
ssl: Let's Encrypt
monitoring: Grafana + Loki + Sentry
dns: Cloudflare
```

---

## 📁 Project Structure to Create

```
ucg-studio/
├── frontend/                          # Vue 3 application
│   ├── src/
│   │   ├── components/
│   │   │   ├── common/                # Reusable UI components
│   │   │   ├── auth/                  # Login, Signup, Password Reset
│   │   │   ├── dashboard/             # Dashboard widgets
│   │   │   ├── project/               # Project creation & settings
│   │   │   └── production/            # Production table components
│   │   ├── views/                     # Route pages
│   │   ├── stores/                    # Pinia stores
│   │   ├── composables/               # Reusable composition functions
│   │   ├── utils/                     # Helper functions
│   │   ├── lib/
│   │   │   └── supabase.js            # Supabase client initialization
│   │   ├── router/
│   │   │   └── index.js               # Vue Router config
│   │   ├── assets/
│   │   │   └── styles/
│   │   │       └── main.css           # Tailwind imports
│   │   ├── App.vue
│   │   └── main.js
│   ├── public/
│   ├── index.html
│   ├── package.json
│   ├── vite.config.js
│   ├── tailwind.config.js
│   ├── Dockerfile
│   └── .env.example
├── database/
│   └── schema.sql                     # Already provided
├── deployment/
│   ├── docker-compose.yml             # Already provided
│   ├── nginx.conf                     # To be created
│   ├── .env.example                   # Already provided
│   └── ssl/                           # Certbot managed
├── docs/                              # Already provided
├── scripts/
│   ├── setup.sh
│   ├── deploy.sh
│   └── backup.sh
└── README.md                          # Already provided
```

---

## 🎨 Design System (From Images Provided)

### Colors
```javascript
// tailwind.config.js colors
colors: {
  primary: {
    DEFAULT: '#1313EC',  // Primary Blue
  },
  success: {
    DEFAULT: '#22D34E',  // Success Green
  },
  neutral: {
    50: '#F8F8F8',       // Background
    900: '#111118',      // Text
  }
}
```

### Typography
```
Font: Inter
H1 Display: 36px/40px, 900 weight
H1 Heading: 24px/32px, 700 weight
Body: 16px/24px, 400 weight
Small: 14px/20px, 400 weight
```

### Key Components Identified from Images
1. Production Table Row (with shot preview, status badges)
2. Media Card Component (video thumbnails with states)
3. AI Generation Badges (Recommended, Generating, Success, Error)
4. Prompt Selector (Variant A/B/C picker)
5. Button variants (Primary, Secondary, Disabled)

---

## 🚀 MVP Features (Priority Order)

### Phase 1: Foundation (Build First)
1. **Authentication System**
   - Login page
   - Signup page
   - Password reset
   - Supabase Auth integration
   - Protected routes

2. **Dashboard**
   - User profile header with credit balance
   - Project list (empty state + populated)
   - "New Project" button
   - Quick stats widget

### Phase 2: Core Workflow
3. **Create Project Flow**
   - Multi-step modal/form
   - Project settings (name, language, AI budget, aspect ratio, resolution)
   - Script input (textarea with character count)
   - Script breakdown API call to n8n

4. **Production Table (THE CORE FEATURE)**
   - Data table component
   - Shot row with:
     - Shot number, duration, script text
     - Prompt selector (3 alternatives dropdown)
     - Generation button + status indicator
     - Audio/video preview players
   - Bulk selection & generation
   - Real-time status updates via Supabase subscriptions

5. **Audio/Video Generation**
   - n8n webhook integration
   - File upload to Supabase Storage
   - Progress tracking
   - Error handling with credit refund

### Phase 3: Export & Credits
6. **Export System**
   - Client-side ZIP creation (JSZip library)
   - File naming: shot_01_video.mp4, shot_01_audio.mp3
   - Download trigger

7. **Credit System**
   - Credit balance display
   - Transaction history view
   - Low credit warnings
   - Payment integration (Wave/Orange Money webhooks)

8. **Settings Pages**
   - Profile settings
   - ElevenLabs API key integration
   - Notification preferences

### Phase 4: Admin
9. **Admin Dashboard**
   - Platform stats
   - User management table
   - Platform settings editor (JSONB)
   - Failed jobs viewer

---

## 💾 Database Understanding

**Key Tables You'll Interact With:**

```sql
-- User data
profiles (id, full_name, credit_balance, elevenlabs_api_key, role, status)

-- Projects
projects (id, user_id, name, slug, script, ai_budget_percentage, status, total_shots)

-- Video segments
shots (
  id, project_id, shot_number, script_text, duration_seconds,
  ai_prompt_1, ai_prompt_2, ai_prompt_3, selected_prompt,
  generation_status, audio_file_url, video_file_url,
  voice_settings JSONB
)

-- Credits
credit_transactions (user_id, transaction_type, amount, previous_balance, new_balance)

-- Payments
payment_transactions (user_id, payment_provider, credits_purchased, payment_status)
```

**Important:** Database has RLS enabled. All queries run with `auth.uid()` context.

---

## 🔌 API Integration Patterns

### Supabase Client Usage

```javascript
// lib/supabase.js
import { createClient } from '@supabase/supabase-js'

export const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
)
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
      body: JSON.stringify({
        project_id: projectId,
        script,
        ai_budget_percentage: aiBudget
      })
    })
    
    if (!response.ok) throw new Error('Script breakdown failed')
    return response.json()
  }

  return { scriptBreakdown }
}
```

### Real-time Subscriptions

```javascript
// In component
const channel = supabase
  .channel('shots-realtime')
  .on('postgres_changes', {
    event: 'UPDATE',
    schema: 'public',
    table: 'shots',
    filter: `project_id=eq.${projectId}`
  }, (payload) => {
    // Update local state when shot status changes
    updateShotInState(payload.new)
  })
  .subscribe()

// Cleanup
onUnmounted(() => channel.unsubscribe())
```

---

## 🎯 Critical Implementation Details

### 1. Credit Deduction Flow
```
User clicks "Generate" 
  → Client checks: user has enough credits?
  → If yes: Immediately deduct credits (UPDATE profiles)
  → Trigger: Inserts credit_transaction record
  → Trigger: Updates user balance
  → Call n8n webhook
  → n8n returns base64 media
  → Upload to Supabase Storage
  → Update shot with file URLs
  → If failed: Trigger refunds credits automatically
```

### 2. Generation Status States
```
pending → generating → completed
                    ↘ failed (auto-refund)
```

### 3. File Storage Pattern
```
Bucket: generated-media
Path: /{user_id}/shot_{shot_number}_{type}.{ext}
Example: /uuid-123/shot_01_video.mp4
         /uuid-123/shot_01_audio.mp3
```

### 4. Project Slug Generation
```javascript
// Pattern: {username}-{project-name}-{number}
// Example: elhadji-coffee-tutorial-1

function generateSlug(userId, projectName) {
  const username = user.email.split('@')[0]
  const base = `${username}-${slugify(projectName)}`
  
  // Check existing count
  const count = await countExistingWithBase(base)
  return `${base}-${count + 1}`
}
```

---

## 🚨 Critical Rules & Constraints

### Security
- ✅ **All database queries use RLS** - Users only see their own data
- ✅ **Never expose API keys client-side** - Store in environment variables
- ✅ **Validate all inputs** - Both client and server-side
- ✅ **Use Supabase Auth exclusively** - Don't build custom auth

### Performance
- ✅ **Use Supabase Realtime** - Don't poll for updates
- ✅ **Lazy load components** - Vue's defineAsyncComponent
- ✅ **Optimize images** - WebP format, proper sizing
- ✅ **Cache API responses** - Use Pinia stores

### UX Requirements
- ✅ **Show loading states** - Every async operation
- ✅ **Display errors gracefully** - Toast notifications
- ✅ **Confirm destructive actions** - Delete project modal
- ✅ **Auto-save when possible** - Project drafts
- ✅ **Mobile responsive** - Tailwind breakpoints

### Business Logic
- ✅ **Credits deducted immediately** - Before generation starts
- ✅ **Automatic refunds on failure** - Via database trigger
- ✅ **Storage quota checks** - Before upload (1GB per user)
- ✅ **Low credit warnings** - At admin-defined threshold

---

## 📝 Code Quality Standards

### Vue Component Structure
```vue
<script setup>
// 1. Imports
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'

// 2. Composables
const router = useRouter()

// 3. State
const isLoading = ref(false)
const error = ref(null)

// 4. Computed
const hasError = computed(() => error.value !== null)

// 5. Methods
async function fetchData() {
  isLoading.value = true
  try {
    // Logic here
  } catch (err) {
    error.value = err.message
  } finally {
    isLoading.value = false
  }
}

// 6. Lifecycle
onMounted(() => {
  fetchData()
})
</script>

<template>
  <div class="container">
    <!-- Clean, semantic HTML -->
  </div>
</template>

<style scoped>
/* Minimal custom CSS, prefer Tailwind */
</style>
```

### Error Handling Pattern
```javascript
try {
  const { data, error } = await supabase
    .from('projects')
    .select('*')
  
  if (error) throw error
  
  return data
} catch (error) {
  console.error('Failed to fetch projects:', error)
  Sentry.captureException(error)
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

## 🧪 Testing Checklist

For each feature you build:

- [ ] Happy path works (successful flow)
- [ ] Error states handled (API failures, network errors)
- [ ] Loading states shown (spinners, skeletons)
- [ ] Empty states displayed (no projects, no shots)
- [ ] Mobile responsive (test at 375px, 768px, 1440px)
- [ ] Keyboard accessible (tab navigation works)
- [ ] Real-time updates work (Supabase subscriptions)
- [ ] Credits deduct/refund correctly
- [ ] RLS policies enforced (users can't see others' data)

---

## 🚀 Development Workflow

### Day 1: Setup
```bash
# 1. Initialize Vue project
npm create vite@latest frontend -- --template vue
cd frontend
npm install

# 2. Install dependencies
npm install @supabase/supabase-js pinia vue-router
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# 3. Setup Supabase
# Create lib/supabase.js with client initialization

# 4. Configure Tailwind
# Add design system colors from images

# 5. Create basic layout
# App.vue, router, stores
```

### Day 2-3: Authentication
```bash
# 1. Build auth pages (Login, Signup, Password Reset)
# 2. Implement Supabase Auth
# 3. Setup protected routes
# 4. Create user profile header
```

### Day 4-5: Dashboard & Projects
```bash
# 1. Dashboard view with project list
# 2. Create project modal/form
# 3. Project detail view
# 4. Script input & breakdown
```

### Day 6-8: Production Table (Most Complex)
```bash
# 1. Production table component
# 2. Shot row components
# 3. Prompt selector
# 4. Generation buttons & status
# 5. Audio/video players
# 6. Real-time updates
```

### Day 9-10: Generation & Storage
```bash
# 1. n8n webhook integration
# 2. File upload to Supabase Storage
# 3. Credit deduction logic
# 4. Error handling & refunds
```

### Day 11-12: Export & Credits
```bash
# 1. Export functionality (JSZip)
# 2. Credit system UI
# 3. Payment integration
# 4. Settings pages
```

### Day 13-14: Polish & Deploy
```bash
# 1. Admin dashboard
# 2. Bug fixes
# 3. Performance optimization
# 4. Production deployment
```

---

## 🎯 Your First Task

**Start here:**

1. **Read README.md completely** (understand the full spec)
2. **Review database/schema.sql** (understand data model)
3. **Initialize Vue project** (follow structure above)
4. **Build authentication** (login, signup, protected routes)
5. **Create dashboard** (empty state + project list)

Once these 5 are done, we'll tackle the production table.

---

## 💡 Pro Tips for Claude Code

1. **Read all docs first** - Don't guess, the specs are comprehensive
2. **Follow the design system** - Use exact colors from images
3. **Build iteratively** - Complete one feature before starting next
4. **Test as you go** - Run app locally after each component
5. **Ask for clarification** - If spec is unclear, ask before coding
6. **Commit frequently** - Small, focused commits
7. **Use TypeScript sparingly** - Only if it helps, don't over-complicate
8. **Prefer composition API** - <script setup> syntax
9. **Keep components small** - Under 200 lines each
10. **Reference the schema** - Database is the source of truth

---

## 🆘 When You Need Help

**For understanding requirements:**
- Re-read relevant section in README.md
- Check database/schema.sql for data structures
- Review docs/FILE_STRUCTURE.md for organization

**For implementation details:**
- Vue 3 docs: https://vuejs.org
- Supabase docs: https://supabase.com/docs
- TailwindCSS docs: https://tailwindcss.com
- Pinia docs: https://pinia.vuejs.org

**For debugging:**
- Check browser console
- Check Supabase logs (Dashboard → Logs)
- Check network tab (API calls)
- Review RLS policies (might be blocking query)

---

## ✅ Success Criteria

**You'll know you're on track when:**

- [ ] Users can signup/login successfully
- [ ] Dashboard loads with real data from Supabase
- [ ] Projects can be created and saved
- [ ] Script breakdown returns segments from n8n
- [ ] Production table displays all shots
- [ ] Generation triggers correctly
- [ ] Real-time updates work (status changes live)
- [ ] Credits deduct and refund properly
- [ ] Export downloads ZIP file
- [ ] Mobile layout doesn't break
- [ ] No errors in console
- [ ] App loads in <2 seconds

---

## 🎉 Ready to Build!

You have:
- ✅ Complete specification (README.md)
- ✅ Production-ready database schema
- ✅ Clear development roadmap
- ✅ Design system reference (from images)
- ✅ All technical requirements documented

**Now go build UCG Studio!** 🚀

Start with authentication, build the production table carefully (it's the core), and ship by Feb 14th.

You got this! 💪

---

**Last Updated:** January 20, 2026  
**For:** Claude Code (Anthropic)  
**Project:** UCG Studio MVP  
**Timeline:** 23 days to launch
