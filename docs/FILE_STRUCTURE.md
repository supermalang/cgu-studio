# Jelika - Recommended File Structure

## Complete Project Structure

```
jelika/
├── .git/
├── .github/
│   └── workflows/
│       └── deploy.yml                 # GitHub Actions CI/CD
│
├── frontend/                          # Vue 3 + Vite Application
│   ├── public/
│   │   ├── favicon.ico
│   │   └── robots.txt
│   ├── src/
│   │   ├── assets/
│   │   │   ├── images/
│   │   │   └── styles/
│   │   │       └── main.css           # Tailwind imports
│   │   ├── components/
│   │   │   ├── common/
│   │   │   │   ├── AppHeader.vue
│   │   │   │   ├── AppSidebar.vue
│   │   │   │   ├── Button.vue
│   │   │   │   ├── Modal.vue
│   │   │   │   └── Tooltip.vue
│   │   │   ├── auth/
│   │   │   │   ├── LoginForm.vue
│   │   │   │   ├── SignupForm.vue
│   │   │   │   └── PasswordReset.vue
│   │   │   ├── dashboard/
│   │   │   │   ├── DashboardStats.vue
│   │   │   │   ├── ProjectCard.vue
│   │   │   │   └── QuickActions.vue
│   │   │   ├── project/
│   │   │   │   ├── CreateProjectModal.vue
│   │   │   │   ├── ProjectSettings.vue
│   │   │   │   └── ScriptInput.vue
│   │   │   └── production/
│   │   │       ├── ProductionTable.vue
│   │   │       ├── ShotRow.vue
│   │   │       ├── PromptSelector.vue
│   │   │       ├── AudioPlayer.vue
│   │   │       ├── VideoPlayer.vue
│   │   │       └── GenerationProgress.vue
│   │   ├── views/
│   │   │   ├── auth/
│   │   │   │   ├── LoginView.vue
│   │   │   │   ├── SignupView.vue
│   │   │   │   └── PasswordResetView.vue
│   │   │   ├── dashboard/
│   │   │   │   └── DashboardView.vue
│   │   │   ├── project/
│   │   │   │   ├── ProjectListView.vue
│   │   │   │   ├── ProjectDetailView.vue
│   │   │   │   └── ProductionTableView.vue
│   │   │   ├── settings/
│   │   │   │   ├── ProfileSettings.vue
│   │   │   │   ├── IntegrationsSettings.vue
│   │   │   │   └── BillingSettings.vue
│   │   │   └── admin/
│   │   │       ├── AdminDashboard.vue
│   │   │       ├── UserManagement.vue
│   │   │       ├── PlatformSettings.vue
│   │   │       └── FailedJobs.vue
│   │   ├── stores/
│   │   │   ├── auth.js                # Pinia store for auth
│   │   │   ├── projects.js            # Projects state
│   │   │   ├── shots.js               # Shots state
│   │   │   ├── credits.js             # Credit balance
│   │   │   └── notifications.js       # In-app notifications
│   │   ├── composables/
│   │   │   ├── useSupabase.js         # Supabase client
│   │   │   ├── useN8n.js              # n8n webhook calls
│   │   │   ├── useCredits.js          # Credit operations
│   │   │   ├── useStorage.js          # File upload/download
│   │   │   └── useRealtime.js         # Realtime subscriptions
│   │   ├── utils/
│   │   │   ├── api.js                 # API helpers
│   │   │   ├── validation.js          # Form validation
│   │   │   ├── formatting.js          # Date, number formatting
│   │   │   └── constants.js           # App constants
│   │   ├── router/
│   │   │   └── index.js               # Vue Router config
│   │   ├── lib/
│   │   │   └── supabase.js            # Supabase initialization
│   │   ├── App.vue
│   │   └── main.js
│   ├── .env.example
│   ├── .env.local                     # Git-ignored
│   ├── Dockerfile
│   ├── package.json
│   ├── vite.config.js
│   ├── tailwind.config.js
│   └── index.html
│
├── database/
│   ├── schema.sql                     # Complete DB schema
│   ├── migrations/
│   │   ├── 001_initial_schema.sql
│   │   ├── 002_add_avatars.sql
│   │   └── 003_add_environments.sql
│   ├── seeds/
│   │   └── admin_settings.sql
│   └── rpc_functions/
│       ├── admin_functions.sql
│       └── user_functions.sql
│
├── n8n/
│   ├── workflows/
│   │   ├── script-breakdown.json      # Export of n8n workflow
│   │   ├── audio-generation.json
│   │   ├── video-generation.json
│   │   ├── avatar-creation.json
│   │   ├── environment-creation.json
│   │   └── payment-webhooks.json
│   └── credentials/
│       └── README.md                  # How to setup credentials
│
├── deployment/
│   ├── docker-compose.yml
│   ├── .env.example
│   ├── .env                           # Git-ignored
│   ├── nginx.conf
│   ├── loki-config.yml
│   ├── promtail-config.yml
│   └── ssl/                           # Git-ignored
│       ├── fullchain.pem
│       └── privkey.pem
│
├── docs/
│   ├── README.md                      # Complete spec (this file)
│   ├── FILE_STRUCTURE.md
│   ├── DEPLOYMENT_GUIDE.md
│   ├── API_DOCUMENTATION.md
│   ├── DATABASE_SCHEMA.md
│   ├── UI_SPECIFICATIONS.md
│   └── DEVELOPMENT_GUIDE.md
│
├── scripts/
│   ├── setup.sh                       # Initial setup script
│   ├── deploy.sh                      # Deployment script
│   ├── backup.sh                      # Backup script
│   └── restore.sh                     # Restore script
│
├── .gitignore
├── README.md
└── LICENSE

```

## Frontend Component Hierarchy

```
App.vue
├── AppHeader.vue
│   ├── CreditBalance.vue
│   └── UserMenu.vue
├── AppSidebar.vue
└── Router View
    ├── DashboardView.vue
    │   ├── DashboardStats.vue
    │   ├── ProjectCard.vue (multiple)
    │   └── EmptyState.vue
    ├── ProjectDetailView.vue
    │   ├── ProjectSettings.vue
    │   └── ProductionTableView.vue
    │       └── ProductionTable.vue
    │           └── ShotRow.vue (multiple)
    │               ├── PromptSelector.vue
    │               ├── GenerationProgress.vue
    │               ├── AudioPlayer.vue
    │               └── VideoPlayer.vue
    └── SettingsView.vue
        ├── ProfileSettings.vue
        ├── IntegrationsSettings.vue
        └── BillingSettings.vue
```

## Key Files Breakdown

### Frontend

#### `main.js`
```javascript
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import router from './router'
import App from './App.vue'
import './assets/styles/main.css'
import * as Sentry from '@sentry/vue'

const app = createApp(App)

Sentry.init({
  app,
  dsn: import.meta.env.VITE_SENTRY_DSN,
  environment: import.meta.env.NODE_ENV,
})

app.use(createPinia())
app.use(router)
app.mount('#app')
```

#### `lib/supabase.js`
```javascript
import { createClient } from '@supabase/supabase-js'

export const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
)
```

#### `composables/useN8n.js`
```javascript
export function useN8n() {
  const apiKey = import.meta.env.VITE_N8N_API_KEY
  const baseUrl = import.meta.env.VITE_N8N_WEBHOOK_URL

  async function scriptBreakdown(projectId, script, aiBudget) {
    const response = await fetch(`${baseUrl}/webhook/script-breakdown`, {
      method: 'POST',
      headers: {
        'X-API-Key': apiKey,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ project_id: projectId, script, ai_budget_percentage: aiBudget }),
    })
    return response.json()
  }

  // ... other n8n functions

  return { scriptBreakdown, generateAudio, generateVideo }
}
```

### Database

#### Recommended Migration Strategy

**Create migrations sequentially:**
1. `001_initial_schema.sql` - Core tables (profiles, projects, shots)
2. `002_add_credit_system.sql` - Credit transactions, payments
3. `003_add_notifications.sql` - Notifications table
4. `004_add_avatars.sql` - Avatars, wardrobes (future)
5. `005_add_environments.sql` - Environments (future)

### Deployment

#### Directory Structure on VM

```
/var/www/jelika/
├── frontend/           # Cloned from Git
├── deployment/         # Cloned from Git
│   ├── docker-compose.yml
│   ├── .env           # Created manually
│   └── ssl/           # Certbot managed
├── n8n/               # n8n workflows exported
└── backups/
    ├── database/      # Daily Supabase exports
    ├── n8n/           # n8n workflow backups
    └── storage/       # S3 backup logs
```

---

## Getting Started

### 1. Clone Repository
```bash
git clone https://github.com/your-username/jelika.git
cd jelika
```

### 2. Frontend Setup
```bash
cd frontend
npm install
cp .env.example .env.local
# Edit .env.local with your keys
npm run dev
```

### 3. Database Setup
```bash
# In Supabase Dashboard:
# 1. Create new project
# 2. Run schema.sql in SQL Editor
# 3. Enable Realtime on tables
```

### 4. n8n Setup
```bash
# Import workflows from n8n/ directory
# Configure credentials in n8n dashboard
```

### 5. Deploy to Production
```bash
cd deployment
cp .env.example .env
# Edit .env with production keys
docker-compose up -d
```

---

**See DEPLOYMENT_GUIDE.md for detailed deployment instructions.**
