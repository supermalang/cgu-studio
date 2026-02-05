# UCG Studio

**AI-Powered Video Production Platform** for creating consistent short-form video content

[![Status](https://img.shields.io/badge/status-in%20development-yellow)](https://github.com)
[![Phase](https://img.shields.io/badge/phase-1%20complete-green)](https://github.com)
[![License](https://img.shields.io/badge/license-proprietary-blue)](https://github.com)

---

## Overview

UCG Studio helps content creators turn scripts into professional short-form videos using AI. Paste your script, and our platform automatically breaks it into optimized segments, generates voiceovers and video clips, and exports organized files ready for editing.

### Key Features

- **Smart Script Breakdown** - AI segments your script into optimal 2-8 second video shots
- **3 Camera Angles** - Get 3 AI prompt alternatives for each shot
- **AI Voice Generation** - ElevenLabs integration for professional voiceovers
- **Video Generation** - Google Veo 3 powered video clips
- **AI Budget Control** - Mix AI-generated and stock footage (20-100% AI)
- **Batch Production** - Intuitive table interface for managing 30+ shots
- **Export Ready** - Download organized, numbered clips for final editing

### Target Launch

**February 14, 2026** (MVP)

---

## Technology Stack

### Frontend
- **Framework:** Vue 3 (Composition API)
- **Build Tool:** Vite
- **Styling:** TailwindCSS with custom design system
- **State Management:** Pinia
- **Routing:** Vue Router

### Backend
- **Database:** Supabase (PostgreSQL 15)
- **Authentication:** Supabase Auth (Email + Google OAuth)
- **Storage:** Supabase Storage (3 buckets)
- **Realtime:** Supabase Realtime subscriptions
- **Automation:** n8n (self-hosted workflows)

### Infrastructure
- **Hosting:** Docker on DigitalOcean
- **Reverse Proxy:** Nginx
- **SSL:** Let's Encrypt
- **Monitoring:** Grafana + Loki + Sentry
- **DNS:** Cloudflare

---

## Quick Start

### Prerequisites

- Node.js 18+
- npm or yarn
- Supabase account

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ucg-studio
   ```

2. **Install dependencies**
   ```bash
   cd frontend
   npm install
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env.local
   # Edit .env.local with your Supabase credentials
   ```

4. **Start development server**
   ```bash
   npm run dev
   ```

5. **Visit the app**
   ```
   http://localhost:5173
   ```

### Database Setup

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Copy your project URL and anon key
3. Run the database schema:
   - Open Supabase Dashboard → SQL Editor
   - Paste contents of [database/schema.sql](database/schema.sql)
   - Execute the query
4. Enable Realtime on tables:
   - Dashboard → Database → Replication
   - Enable for: `projects`, `shots`, `notifications`

**Troubleshooting:** If you encounter issues, see [docs/QUICK_FIX_GUIDE.md](docs/QUICK_FIX_GUIDE.md)

---

## Project Structure

```
ucg-studio/
├── frontend/              # Vue 3 application
│   ├── src/
│   │   ├── components/   # Reusable components
│   │   ├── views/        # Page components
│   │   ├── stores/       # Pinia stores
│   │   ├── composables/  # Composition functions
│   │   ├── lib/          # External services (Supabase)
│   │   └── router/       # Vue Router config
│   ├── .env.local        # Environment variables
│   └── package.json      # Dependencies
├── database/
│   └── schema.sql        # PostgreSQL schema
├── deployment/
│   ├── docker-compose.yml # Production config
│   └── .env.example      # Environment template
├── docs/                 # Documentation
│   ├── README.md         # Complete technical spec
│   ├── DESIGN_SYSTEM.md  # UI design reference
│   ├── PROGRESS.md       # Development tracker
│   ├── GETTING_STARTED.md # Setup guide
│   └── ...
├── CLAUDE.md             # AI assistant guide
└── README.md             # This file
```

---

## Environment Variables

Create a `.env.local` file in the `frontend/` directory:

```env
# Supabase
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here

# n8n (for automation)
VITE_N8N_API_KEY=your-n8n-api-key
VITE_N8N_WEBHOOK_URL=https://n8n.your-domain.com

# App
VITE_APP_URL=http://localhost:5173
```

---

## Design System

### Color Palette

- **Primary Blue:** `#1313EC` (9 shades: 50-900)
- **Success Green:** `#22D34E` (9 shades: 50-900)
- **Error Red:** `#F04438` (9 shades: 50-900)
- **Warning Orange:** `#F79009` (9 shades: 50-900)
- **Neutral Gray:** 10 shades from `#F8F8F8` to `#111118`

### Typography

- **Font Family:** Inter (400, 500, 600, 700, 900)
- **Scale:** 8 predefined sizes (xs to 4xl)
- **Optimized line heights** for readability

### Pre-built Components

The design system includes 50+ Tailwind utility classes:
- Buttons (Primary, Secondary, Ghost, Danger)
- Inputs with validation states
- Cards (Basic, Hover, Interactive)
- Badges (5 color variants + 5 status variants)
- Alerts (Info, Success, Warning, Error)
- Loading states (Spinners, Skeletons, Progress)

**Full documentation:** [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md)

---

## Development Status

### Phase 1: Foundation ✅ (Complete)

- [x] Vue 3 project setup with Vite
- [x] Supabase integration
- [x] Authentication system (Email + Google OAuth)
- [x] Protected routes
- [x] User dashboard
- [x] Profile header with credit balance
- [x] Complete design system
- [x] Production build verified

### Phase 2: Core Workflow 🚧 (In Progress)

- [ ] Project creation flow
- [ ] Production table interface
- [ ] Script breakdown (n8n integration)
- [ ] Audio/video generation
- [ ] Real-time status updates
- [ ] Export system

### Phase 3: Polish & Launch 📅 (Planned)

- [ ] Credit system UI
- [ ] Payment integration (Wave/Orange Money)
- [ ] Admin dashboard
- [ ] Settings pages
- [ ] Final testing and deployment

See [docs/PROGRESS.md](docs/PROGRESS.md) for detailed tracking.

---

## Documentation

### For Developers

- **[CLAUDE.md](CLAUDE.md)** - AI assistant development guide
- **[docs/GETTING_STARTED.md](docs/GETTING_STARTED.md)** - Detailed setup guide
- **[docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md)** - Complete design reference
- **[docs/COMPONENT_LIBRARY.md](docs/COMPONENT_LIBRARY.md)** - Component documentation

### Technical Specifications

- **[docs/README.md](docs/README.md)** - Complete technical specification (2100+ lines)
- **[database/schema.sql](database/schema.sql)** - Full database schema
- **[docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)** - Production deployment guide

### Quick References

- **[docs/START_HERE.md](docs/START_HERE.md)** - Quick start for new contributors
- **[docs/QUICK_FIX_GUIDE.md](docs/QUICK_FIX_GUIDE.md)** - Common issues and solutions

---

## Building & Deployment

### Development

```bash
# Start dev server with hot reload
npm run dev

# Type check (if using TypeScript)
npm run type-check

# Lint code
npm run lint
```

### Production

```bash
# Build for production
npm run build

# Preview production build locally
npm run preview
```

### Docker Deployment

```bash
# Navigate to deployment directory
cd deployment

# Configure environment
cp .env.example .env
# Edit .env with production values

# Start services
docker-compose up -d

# View logs
docker-compose logs -f
```

For complete deployment instructions, see [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)

---

## Key Concepts

### Credit System

- New users start with **0 credits**
- Credit packages: $5 (250 credits), $20 (1000 credits), $50 (3000 credits)
- Costs per shot:
  - Script breakdown: 10 credits
  - Audio generation: 2 credits
  - Video generation: 50 credits
- Automatic refunds on generation failures

### AI Budget

Users control cost vs quality with an AI Budget slider (20-100%):
- **80% AI Budget** = 80% AI-generated clips + 20% stock footage recommendations
- System intelligently suggests stock for generic scenes to save costs

### Production Workflow

1. User creates project and pastes script
2. AI breaks script into 2-8 second segments (30+ shots typical)
3. For each segment, AI generates 3 camera angle prompts
4. User selects preferred prompt and generates audio + video
5. Real-time updates show generation progress
6. Export downloads ZIP with organized, numbered files

---

## Contributing

This is currently a solo development project with a tight deadline. Contributions will be welcome after the MVP launch!

### Code Style

- Follow Vue 3 Composition API patterns
- Use Tailwind utility classes (avoid custom CSS)
- Implement proper error handling
- Add loading states for async operations
- Test on mobile breakpoints

---

## Support & Resources

### External Documentation

- [Vue 3 Documentation](https://vuejs.org)
- [Supabase Documentation](https://supabase.com/docs)
- [TailwindCSS Documentation](https://tailwindcss.com)
- [Pinia Documentation](https://pinia.vuejs.org)
- [n8n Documentation](https://docs.n8n.io)

### Getting Help

1. Check [docs/](docs/) folder for guides
2. Review [database/schema.sql](database/schema.sql) for data structure
3. See [CLAUDE.md](CLAUDE.md) for development patterns
4. Review [docs/PROGRESS.md](docs/PROGRESS.md) for current status

---

## License

**Proprietary** - All rights reserved

---

## Acknowledgments

Built with:
- [Vue.js](https://vuejs.org) - Progressive JavaScript framework
- [Supabase](https://supabase.com) - Open source Firebase alternative
- [TailwindCSS](https://tailwindcss.com) - Utility-first CSS framework
- [ElevenLabs](https://elevenlabs.io) - AI voice generation
- [Google Veo](https://deepmind.google/technologies/veo/) - AI video generation

---

**Last Updated:** January 20, 2026
**Status:** Phase 1 Complete, Phase 2 In Progress
**Built with ❤️ using Claude Code**
