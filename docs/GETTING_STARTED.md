# Getting Started with UCG Studio Development

## Quick Setup (5 minutes)

### 1. Prerequisites
- Node.js 18+ installed
- npm or yarn
- A Supabase account (free tier works)

### 2. Database Setup

1. Go to [https://supabase.com](https://supabase.com) and create a new project
2. Wait for the database to provision (2-3 minutes)
3. Go to **SQL Editor** in the Supabase dashboard
4. Copy the entire contents of `database/schema.sql`
5. Paste and run it in the SQL Editor
6. Go to **Database > Replication** and enable realtime for these tables:
   - projects
   - shots
   - notifications

### 3. Get Your API Keys

1. In Supabase Dashboard, go to **Settings > API**
2. Copy these values:
   - Project URL (looks like: `https://xxxxx.supabase.co`)
   - Anon public key (looks like: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`)

### 4. Configure Environment

```bash
# Navigate to frontend directory
cd frontend

# Copy the environment template
cp .env.example .env.local

# Edit .env.local with your keys
nano .env.local  # or use your preferred editor
```

Update these values in `.env.local`:
```env
VITE_SUPABASE_URL=https://your-project-id.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
VITE_APP_URL=http://localhost:5173
```

### 5. Install & Run

```bash
# Install dependencies (one time only)
npm install

# Start development server
npm run dev
```

Visit [http://localhost:5173](http://localhost:5173) 🎉

---

## First Time Using the App

### Create Your First Account

1. Click **"Sign up"**
2. Enter your details:
   - Full Name: Your name
   - Email: Your email
   - Password: At least 6 characters
3. Check **"I agree to the Terms of Service"**
4. Click **"Sign up"**
5. Check your email for verification (Supabase sends this automatically)
6. Click the verification link
7. Log in with your credentials

### Navigate the Dashboard

After logging in, you'll see:
- **Welcome message** with your name
- **Quick stats** showing:
  - Total Projects (0 initially)
  - Credits Available (0 by default)
  - Active Projects (0 initially)
- **Empty state** prompting you to create your first project

### Create Your First Admin User (Optional)

To test admin features:

1. Go to Supabase Dashboard > **Authentication > Users**
2. Find your user
3. Click to edit
4. Go to **Database > profiles** table
5. Find your profile record
6. Edit the `role` column from `user` to `admin`
7. Refresh the app
8. You'll now see an "Admin" option in your user menu

---

## Development Workflow

### Running the App

```bash
# Development server with hot reload
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

### Project Structure

```
frontend/src/
├── components/     # Reusable Vue components
│   ├── auth/      # ✅ Login, Signup, Password Reset
│   ├── common/    # ✅ AppHeader
│   └── ...        # Add more as you build
├── views/         # Page-level components
│   ├── auth/      # ✅ Auth views
│   ├── dashboard/ # ✅ Dashboard
│   └── ...        # Project detail, settings, admin
├── stores/        # Pinia state management
│   └── auth.js    # ✅ Authentication store
├── router/        # Vue Router configuration
│   └── index.js   # ✅ Routes & guards
└── lib/           # External service clients
    └── supabase.js # ✅ Supabase client
```

### Making Changes

1. **Edit a component** - Changes appear instantly (hot reload)
2. **Add a new route** - Update `src/router/index.js`
3. **Add a new store** - Create file in `src/stores/`
4. **Add a composable** - Create file in `src/composables/`

### Styling with Tailwind

Use the predefined classes:
```vue
<!-- Primary button -->
<button class="btn-primary">Click me</button>

<!-- Input field -->
<input class="input-field" />

<!-- Card container -->
<div class="card">Content here</div>
```

Custom colors:
- `bg-primary` - #1313EC (blue)
- `bg-success` - #22D34E (green)
- `bg-neutral-50` - #F8F8F8 (light gray)
- `text-neutral-900` - #111118 (dark text)

---

## Testing Your Work

### Manual Testing Checklist

- [ ] Sign up with a new email
- [ ] Check email verification works
- [ ] Log in with email/password
- [ ] Log out
- [ ] Reset password
- [ ] View dashboard
- [ ] Credit balance displays correctly
- [ ] Responsive on mobile (inspect in browser dev tools)

### Common Issues & Fixes

**Issue:** "Missing Supabase environment variables"
- **Fix:** Make sure `.env.local` exists and has valid keys

**Issue:** Build fails with Tailwind error
- **Fix:** Make sure you have Tailwind v3 installed: `npm install -D tailwindcss@3`

**Issue:** "Failed to load projects"
- **Fix:** Check that:
  1. Database schema is applied
  2. RLS policies are enabled
  3. Your Supabase keys are correct

**Issue:** Google OAuth doesn't work
- **Fix:** Configure Google OAuth in Supabase:
  1. Go to **Authentication > Providers**
  2. Enable Google
  3. Add your Google client ID/secret
  4. Add authorized redirect URL

---

## Next Development Tasks

See [PROGRESS.md](PROGRESS.md) for the full roadmap.

**Immediate next steps:**
1. Build the Create Project modal
2. Integrate n8n for script breakdown
3. Build the Production Table (the core feature!)

---

## Useful Commands

```bash
# Install new dependency
npm install package-name

# Install dev dependency
npm install -D package-name

# Check for build errors
npm run build

# Format code (if you setup Prettier)
npm run format

# Lint code (if you setup ESLint)
npm run lint
```

---

## Getting Help

- **Documentation:** Check `/docs` folder
- **Database Schema:** `database/schema.sql`
- **Implementation Guide:** `CLAUDE.md`
- **Progress Tracking:** `PROGRESS.md`

---

## Tips for Success

1. **Read the docs first** - CLAUDE.md has all implementation details
2. **Follow the design system** - Use exact colors from Tailwind config
3. **Test as you go** - Run the app after every component
4. **Commit frequently** - Small, focused commits
5. **Check the database** - Use Supabase dashboard to inspect data
6. **Use real-time** - Don't poll, use Supabase subscriptions
7. **Handle errors** - Always show user-friendly error messages
8. **Test on mobile** - Use responsive design breakpoints

---

**Ready to build! Start with creating the project creation flow.** 🚀

For detailed implementation instructions, see [CLAUDE.md](CLAUDE.md)
