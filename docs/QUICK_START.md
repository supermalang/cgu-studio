# UCG Studio - Quick Start Guide

**For:** Solo developer building MVP by February 14, 2026  
**Time to First Deploy:** ~4 hours

---

## Overview

This guide gets you from zero to a working MVP in the fastest way possible.

## Day 1: Foundation (4 hours)

### Hour 1: Setup Accounts & Services

1. **Supabase** (supabase.com)
   - Create new project
   - Copy URL and anon key
   - Run `database/schema.sql` in SQL Editor

2. **DigitalOcean** (digitalocean.com)
   - Create droplet (4CPU, 8GB RAM, Ubuntu 22.04)
   - Note IP address

3. **Domain** (namecheap.com or similar)
   - Purchase domain
   - Point to Cloudflare DNS

4. **Cloudflare** (cloudflare.com)
   - Add domain
   - Create A records for app.domain.com and n8n.domain.com

### Hour 2: Local Development

```bash
# Clone repository
git clone https://github.com/your-username/ucg-studio.git
cd ucg-studio/frontend

# Install dependencies
npm install

# Setup environment
cp .env.example .env.local
nano .env.local  # Add Supabase keys

# Run locally
npm run dev
# Visit http://localhost:5173
```

### Hour 3: Deploy to Production

```bash
# SSH to server
ssh root@your-server-ip

# Run automated setup
curl -fsSL https://raw.githubusercontent.com/your-username/ucg-studio/main/scripts/setup.sh | bash

# Follow prompts to enter API keys
```

### Hour 4: Configure n8n

1. Visit https://n8n.your-domain.com
2. Import workflows from `n8n/workflows/`
3. Add credentials (OpenAI, SendGrid, etc.)
4. Activate all workflows

---

## Day 2-5: Build Core Features (16 hours)

### Priority Order:

1. **Authentication** (2 hours)
   - Login/Signup forms
   - Supabase Auth integration

2. **Dashboard** (2 hours)
   - Project list
   - Credit balance display

3. **Create Project Flow** (4 hours)
   - Project form
   - Script input
   - Script breakdown API call

4. **Production Table** (6 hours)
   - Table component
   - Shot rows
   - Generation buttons
   - Realtime updates

5. **Export** (2 hours)
   - Client-side ZIP creation
   - Download functionality

---

## Day 6-10: Testing & Polish (20 hours)

1. End-to-end testing (8 hours)
2. Bug fixes (6 hours)
3. UI polish (4 hours)
4. Documentation (2 hours)

---

## Day 11-14: Launch Prep (16 hours)

1. Beta testing with 5 users (8 hours)
2. Final bug fixes (4 hours)
3. Marketing preparation (2 hours)
4. Launch! (2 hours)

---

## Minimum Viable Features Checklist

**Must Have (MVP):**
- [ ] User signup/login
- [ ] Create project
- [ ] Script breakdown
- [ ] Production table
- [ ] Audio generation
- [ ] Video generation
- [ ] Export individual clips
- [ ] Credit system
- [ ] Payment (Wave/Orange Money)
- [ ] Admin dashboard

**Nice to Have (Post-MVP):**
- [ ] Stitched video export
- [ ] Avatar library
- [ ] Environment library
- [ ] Team features

---

## Key Shortcuts

### Fastest Development Path:

1. **Use Supabase directly** - No need for custom backend
2. **Client-side processing** - ZIP creation in browser
3. **n8n for automation** - No custom API server needed
4. **Docker for deployment** - One-command deploy
5. **Realtime over polling** - Less server load

### Time Savers:

- Copy-paste components from design system
- Use Supabase RLS instead of custom auth
- Use n8n UI for workflows instead of coding
- Use Tailwind utility classes instead of custom CSS

---

## Daily Checklist Template

**Morning:**
- [ ] Check error logs (Sentry)
- [ ] Review yesterday's progress
- [ ] Set 3 main tasks for today

**During Development:**
- [ ] Commit code every hour
- [ ] Test in browser every 30 minutes
- [ ] Deploy to staging every 4 hours

**Evening:**
- [ ] Push to GitHub
- [ ] Update task list
- [ ] Note blockers for tomorrow

---

## Emergency Contacts

**If Stuck:**
1. Check docs in `/docs` folder
2. Search GitHub Issues
3. Ask in Anthropic Discord
4. Stack Overflow for technical issues

---

## Success Metrics

**Week 1:** Local dev environment working  
**Week 2:** Core features deployed to staging  
**Week 3:** Beta testing with 5 users  
**Week 4:** Launch! 🚀

---

**You got this! Build fast, launch faster.** 💪
