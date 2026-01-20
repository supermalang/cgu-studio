# UCG Studio

AI-Powered Video Production Platform for creating consistent short-form video content.

## 🎯 Project Overview

UCG Studio helps creators produce short-form video content by:
- Breaking scripts into optimized video segments
- Generating audio voiceovers (ElevenLabs)
- Generating AI video clips (Google Veo 3)
- Managing production workflow in an intuitive table interface
- Exporting organized, numbered clips ready for editing

**Target Launch:** February 14, 2026 (MVP)

## 🏗️ Technology Stack

### Frontend
- **Framework:** Vue 3 with Composition API
- **Build Tool:** Vite
- **Styling:** TailwindCSS with custom design system
- **State Management:** Pinia
- **Routing:** Vue Router
- **API Client:** @supabase/supabase-js

### Backend (Serverless)
- **Database:** Supabase (PostgreSQL 15)
- **Authentication:** Supabase Auth (Email + Google OAuth)
- **Storage:** Supabase Storage
- **Realtime:** Supabase Realtime
- **Automation:** n8n (self-hosted workflows)

### Infrastructure
- **Hosting:** DigitalOcean (Docker)
- **Containerization:** Docker Compose
- **Reverse Proxy:** Nginx
- **SSL:** Let's Encrypt
- **Monitoring:** Grafana + Loki + Sentry

## 📁 Project Structure

```
ucg-studio/
├── frontend/           # Vue 3 application
├── database/          # SQL schema and migrations
├── deployment/        # Docker Compose configuration
├── docs/             # Documentation
└── README.md
```

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- npm or yarn
- Supabase account

### Frontend Development

```bash
# Navigate to frontend
cd frontend

# Install dependencies
npm install

# Copy environment template
cp .env.example .env.local

# Edit .env.local with your Supabase credentials

# Start development server
npm run dev
```

Visit [http://localhost:5173](http://localhost:5173)

### Database Setup

1. Create a new Supabase project
2. Copy your project URL and anon key
3. Run the schema in SQL Editor:
   ```bash
   # In Supabase Dashboard > SQL Editor
   # Paste contents of database/schema.sql
   ```
4. **Important:** Fix auth trigger (see [QUICK_FIX_GUIDE.md](QUICK_FIX_GUIDE.md))
5. Enable Realtime on tables (Dashboard > Database > Replication)

**Troubleshooting:** If you get "relation 'profiles' does not exist" error, see [QUICK_FIX_GUIDE.md](QUICK_FIX_GUIDE.md)

## 🎨 Design System

### Colors
- **Primary Blue:** `#1313EC` (9 shades: 50-900)
- **Success Green:** `#22D34E` (9 shades: 50-900)
- **Error Red:** `#F04438` (9 shades: 50-900)
- **Warning Orange:** `#F79009` (9 shades: 50-900)
- **Neutral Gray:** `#F8F8F8` to `#111118` (10 shades)

### Typography
- **Font:** Inter (400, 500, 600, 700, 900)
- **Scale:** 8 predefined sizes (xs to 4xl)
- **Line Heights:** Optimized for readability

### Components
- 50+ pre-built Tailwind classes
- Buttons: Primary, Secondary, Ghost, Danger
- Inputs: Text, Select, Textarea with validation states
- Cards: Basic, Hover, Interactive
- Badges: 5 color variants + 5 status variants
- Alerts: Info, Success, Warning, Error
- Loading: Spinners, Skeletons, Progress bars

**Full documentation:** [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md)

## 📝 MVP Features

### Phase 1: Authentication ✅
- [x] Login page
- [x] Signup page
- [x] Password reset
- [x] Supabase Auth integration
- [x] Protected routes

### Phase 2: Dashboard ✅
- [x] User profile header with credit balance
- [x] Project list
- [x] Quick stats widget
- [ ] "New Project" modal (placeholder)

### Phase 3: Core Workflow (Next)
- [ ] Create Project Flow
- [ ] Production Table
- [ ] Audio/Video Generation
- [ ] Export System
- [ ] Credit System
- [ ] Admin Dashboard

## 🔐 Environment Variables

Create a `.env.local` file in the `frontend/` directory:

```env
# Supabase
VITE_SUPABASE_URL=your-project-url.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key

# n8n
VITE_N8N_API_KEY=your-n8n-api-key
VITE_N8N_WEBHOOK_URL=https://n8n.your-domain.com

# App
VITE_APP_URL=http://localhost:5173
```

## 🐳 Production Deployment

```bash
# Navigate to deployment directory
cd deployment

# Copy environment template
cp .env.example .env

# Edit .env with production credentials

# Start services
docker-compose up -d
```

## 📖 Documentation

- [CLAUDE.md](CLAUDE.md) - Development guide for AI assistant
- [docs/FILE_STRUCTURE.md](docs/FILE_STRUCTURE.md) - Recommended file organization
- [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) - Step-by-step deployment
- [docs/QUICK_START.md](docs/QUICK_START.md) - Fast-track development guide

## 🧪 Testing

```bash
# Run tests (coming soon)
npm run test

# Build for production
npm run build

# Preview production build
npm run preview
```

## 🤝 Contributing

This is a solo development project with a tight deadline. Contributions welcome post-MVP launch!

## 📄 License

Proprietary - All rights reserved

## 🆘 Support

For issues or questions:
- Check documentation in `/docs`
- Review database schema in `database/schema.sql`
- Review CLAUDE.md for implementation details

---

**Built with ❤️ using Claude Code**

**Last Updated:** January 20, 2026
**Status:** In Development (Phase 1 Complete: Authentication ✅)
