# Jelika - Complete Project Specification

**Version:** 1.0.0  
**Last Updated:** January 20, 2026  
**MVP Deadline:** February 14, 2026  

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [User Personas & Flows](#user-personas--flows)
3. [Features & Requirements](#features--requirements)
4. [Technical Architecture](#technical-architecture)
5. [Database Design](#database-design)
6. [API Specifications](#api-specifications)
7. [UI/UX Design](#uiux-design)
8. [Deployment & Infrastructure](#deployment--infrastructure)

---

## 1. PROJECT OVERVIEW

### 1.1 Project Identity

**Name:** Jelika  
**Tagline:** AI-powered end-to-end video production platform for consistent short-form content

### 1.2 Problem Statement

**User Pain Point:**  
Content creators like Elhadji (podcaster) need to create 8-minute videos, but AI video models (like Veo 3) only generate 8-second clips and are expensive. Manually breaking down scripts and managing dozens of short clips is time-consuming and inconsistent.

**Real-World Scenario:**  
Elhadji wants to create an 8-minute podcast video. Current AI tools force him to:
- Manually segment his script into dozens of prompts
- Generate each 8-second clip individually
- Pay expensive API costs for each generation
- Struggle to maintain visual consistency across clips
- Manually compile everything into a final video

### 1.3 Solution

**Jelika's Approach:**  
1. User pastes full script into the platform
2. AI automatically breaks script into optimized 2-8 second segments
3. AI generates 3 camera angle prompts per segment
4. Production table interface allows batch generation of audio + video
5. Smart AI Budget system (20-100%) balances cost by mixing AI and stock footage
6. Export all clips as organized, numbered files ready for editing

### 1.4 Target Audience

**Primary User Persona:**
- **Name:** Elhadji
- **Role:** Solo Podcaster / Content Creator
- **Business:** Podcast production
- **Video Volume:** 8 videos per month
- **Technical Skill:** 3/5 (Comfortable with web apps, not a developer)
- **Budget:** $50 USD/month
- **Location:** West Africa (Senegal, primarily)

**Admin Persona:**
- **Name:** Supermalang
- **Role:** Super Admin / Platform Owner
- **Responsibilities:** User management, platform settings, credit control, analytics

### 1.5 Core Value Proposition

**Unique Differentiators:**
1. **Consistency Engine:** Library of permanent avatars and environments (future feature)
2. **Cost Optimization:** AI Budget slider (20-100%) intelligently mixes AI generation with stock footage
3. **Local Payment Methods:** Wave and Orange Money integration for West African users
4. **User-Friendly Interface:** Non-technical creators can produce professional multi-clip videos
5. **Production Table Workflow:** Intuitive batch generation and preview system

### 1.6 Success Metrics

**3-Month Goals:**
- User engagement (Daily Active Users, time in app)
- Project creation rate
- Script breakdown usage

**6-Month Goals:**
- Transaction volume (credit purchases)
- Customer retention rate
- Average project completion rate

**Target:** 100 users creating ~3 projects each with ~30 shots per project

### 1.7 Project Scope

**IN SCOPE for MVP (by Feb 14):**
- ✅ Script breakdown engine (AI segmentation)
- ✅ Production table with audio/video generation
- ✅ 3 AI prompt alternatives per shot
- ✅ AI vs Stock footage recommendations
- ✅ Export individual clips (ZIP)
- ✅ Credit system with Wave/Orange Money payment
- ✅ User authentication (email + Google OAuth)
- ✅ Admin dashboard (user management, platform settings)
- ✅ Real-time generation status updates

**OUT OF SCOPE for MVP (Future Versions):**
- ❌ Avatar creation and wardrobe management
- ❌ Custom environment library
- ❌ Stitched video export (only individual clips for MVP)
- ❌ Team/workspace features
- ❌ In-app video editor
- ❌ Mobile apps (web-only MVP)

### 1.8 Technical Stack Overview

```
┌─────────────────────────────────────────────┐
│           Frontend (Vue 3 + Vite)           │
│    Hosted: Docker on DigitalOcean VM        │
└─────────────────────────────────────────────┘
                    ↕ HTTPS
┌─────────────────────────────────────────────┐
│         Backend (Supabase Cloud)            │
│  - PostgreSQL Database with RLS             │
│  - Authentication (Email + OAuth)           │
│  - Storage Buckets                          │
│  - Realtime Subscriptions                   │
└─────────────────────────────────────────────┘
                    ↕ Webhooks
┌─────────────────────────────────────────────┐
│        Automation (n8n Self-Hosted)         │
│  - Script Breakdown Workflow                │
│  - Audio Generation (ElevenLabs)            │
│  - Video Generation (Veo 3)                 │
│  - Payment Webhooks (Wave/Orange)           │
└─────────────────────────────────────────────┘
                    ↕ APIs
┌─────────────────────────────────────────────┐
│          External Services                  │
│  - ElevenLabs (Audio)                       │
│  - Google Veo 3 (Video)                     │
│  - SendGrid (Emails)                        │
│  - Sentry (Error Tracking)                  │
│  - Wave & Orange Money (Payments)           │
└─────────────────────────────────────────────┘
```

### 1.9 Timeline & Constraints

**MVP Deadline:** February 14, 2026 (23 days from now)

**Key Constraints:**
- Solo developer (you)
- Starting from zero codebase
- Budget-conscious (leveraging free tiers where possible)
- Must support West African payment methods
- Must be production-ready and scalable to 100 users

---

## 2. USER PERSONAS & FLOWS

### 2.1 User Personas

#### Persona 1: Regular User (Elhadji)

```yaml
name: Elhadji
role: Solo Podcaster
demographics:
  age: 25-35
  location: Dakar, Senegal
  language: French/English
business_type: Podcast production
video_volume: 8 videos per month
technical_skill: 3/5
budget: $50 USD/month
pain_points:
  - Manual script segmentation is time-consuming
  - AI generation costs add up quickly
  - Inconsistent visual style across clips
  - No easy way to manage dozens of clips
goals:
  - Create professional podcast videos efficiently
  - Keep costs under $50/month
  - Maintain consistent branding
tools_used:
  - Generic AI video generators (Runway, Pika)
  - Manual video editing software
  - Stock footage libraries
```

#### Persona 2: Super Admin (Supermalang)

```yaml
name: Supermalang
role: Platform Super Administrator
responsibilities:
  - Platform configuration
  - User management
  - Credit system administration
  - Analytics monitoring
  - n8n workflow management
access_level: Full system access
technical_skill: 5/5
key_tasks:
  - Set credit pricing
  - Configure AI model providers
  - Monitor failed jobs
  - Add/remove credits manually
  - Suspend/unsuspend users
  - View platform-wide analytics
```

### 2.2 Authentication & Onboarding

#### Sign-Up Flow

```
1. User lands on homepage
   ↓
2. Clicks "Get Started"
   ↓
3. Sign-up page with options:
   - Email/Password
   - Continue with Google
   ↓
4. User fills form:
   - Full Name
   - Email
   - Password
   - Country (dropdown)
   - Terms & Conditions (checkbox)
   ↓
5. Supabase sends verification email
   ↓
6. User clicks verification link
   ↓
7. User logs in
   ↓
8. Database seeding (create profile record)
   ↓
9. Redirect to Dashboard with tutorial overlay
```

#### First-Time User Tutorial

**Interactive Modal Approach:**

```
Step 1: "Welcome to Jelika! 🎬"
  → "Let's create your first AI video in minutes"
  → [Next]

Step 2: "This is your credit balance 💰"
  → Highlights credit counter in top-right
  → "You'll need credits to generate videos"
  → [Next]

Step 3: "Click here to start a project ➕"
  → Highlights "New Project" button
  → [Next]

Step 4: "Paste your script and we'll do the rest ✨"
  → Shows script input area
  → [Get Started] or [Skip Tutorial]
```

### 2.3 User Journey Map

#### Happy Path: From Landing to First Video Export

```
┌─────────────────────────────────────────────────────────────┐
│ STAGE 1: DISCOVERY & SIGNUP                                 │
├─────────────────────────────────────────────────────────────┤
│ 1. User lands on jelika.app                              │
│ 2. Reads value proposition                                  │
│ 3. Clicks "Get Started"                                     │
│ 4. Completes signup (email + password)                      │
│ 5. Verifies email                                           │
│ Time: 3-5 minutes                                           │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ STAGE 2: ONBOARDING & SETUP                                 │
├─────────────────────────────────────────────────────────────┤
│ 6. Sees dashboard with tutorial                             │
│ 7. Clicks through 4-step tutorial                           │
│ 8. Purchases first credits ($5 = 250 credits)               │
│    - Selects Wave or Orange Money                           │
│    - Completes payment                                      │
│    - Credits added automatically                            │
│ Time: 5-10 minutes                                          │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ STAGE 3: PROJECT CREATION                                   │
├─────────────────────────────────────────────────────────────┤
│ 9. Clicks "New Project" button                              │
│ 10. Fills project form:                                     │
│     - Name: "My First Podcast"                              │
│     - Language: en-US                                       │
│     - AI Budget: 80%                                        │
│     - Aspect Ratio: 16:9                                    │
│     - Resolution: 1080p                                     │
│ 11. Pastes 3-minute script (500 words)                      │
│ 12. Clicks "Generate Breakdown"                             │
│ Time: 3-5 minutes                                           │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ STAGE 4: SCRIPT BREAKDOWN (AI Processing)                   │
├─────────────────────────────────────────────────────────────┤
│ 13. n8n workflow triggered                                  │
│ 14. AI segments script into 30 shots (2-8s each)            │
│ 15. AI generates 3 prompt alternatives per shot             │
│ 16. AI recommends 24 AI clips + 6 stock clips (80% AI)      │
│ 17. Production table populated with data                    │
│ Time: 30-60 seconds                                         │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ STAGE 5: PRODUCTION TABLE WORKFLOW                          │
├─────────────────────────────────────────────────────────────┤
│ 18. User reviews production table                           │
│ 19. For each AI shot, selects 1 of 3 prompts                │
│ 20. Clicks "Bulk Generate" for first 10 shots               │
│ 21. Audio + Video generation starts:                        │
│     - Audio: 2 credits × 10 = 20 credits                    │
│     - Video: 50 credits × 10 = 500 credits                  │
│ 22. Realtime updates show generation progress               │
│ 23. User previews completed shots                           │
│ 24. Repeats for remaining 20 shots                          │
│ Time: 20-30 minutes (generation time)                       │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ STAGE 6: EXPORT & DOWNLOAD                                  │
├─────────────────────────────────────────────────────────────┤
│ 25. All 30 shots generated successfully                     │
│ 26. User clicks "Export Project"                            │
│ 27. ZIP creation queued (client-side)                       │
│ 28. User receives email: "Export Ready!"                    │
│ 29. Downloads ZIP file containing:                          │
│     - shot_01_video.mp4, shot_01_audio.mp3                  │
│     - shot_02_video.mp4, shot_02_audio.mp3                  │
│     - ... (60 files total)                                  │
│ Time: 2-5 minutes                                           │
└─────────────────────────────────────────────────────────────┘

Total Time: 35-60 minutes from signup to first export
```

### 2.4 Dashboard Elements

**After Login, Users See:**

```
┌─────────────────────────────────────────────────────────────┐
│ Jelika               [Credits: 230] [Profile ▼]         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Welcome back, Elhadji! 👋                                  │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │  📊 Quick Stats                                        │ │
│  │  ┌────────────┬────────────┬────────────┬───────────┐ │ │
│  │  │ Videos: 8  │ Credits    │ Storage    │ Projects  │ │ │
│  │  │            │ Used: 2.3k │ Used: 340MB│ Active: 3 │ │ │
│  │  └────────────┴────────────┴────────────┴───────────┘ │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │        ➕ CREATE NEW PROJECT                           │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  Recent Projects                                            │
│  ┌───────────────────────────────────────────────────────┐ │
│  │ [📹 Thumbnail]  Coffee Shop Tutorial                   │ │
│  │ Status: ✅ Completed | 60 shots | 2,345 credits used   │ │
│  │ Created: Jan 18, 2026 | Last edited: 2 hours ago       │ │
│  │ [Edit] [Export] [Duplicate] [Delete]                   │ │
│  └───────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────┐ │
│  │ [📹 Thumbnail]  Podcast Episode #5                     │ │
│  │ Status: 🔄 In Progress | 12/30 shots | 890 credits     │ │
│  │ Created: Jan 19, 2026 | Last edited: 30 mins ago       │ │
│  │ [Continue] [Export] [Duplicate] [Delete]               │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  [View All Projects →]                                      │
└─────────────────────────────────────────────────────────────┘
```

**Empty State (New Users):**

```
┌─────────────────────────────────────────────────────────────┐
│                          🎬                                 │
│                                                             │
│               No projects yet                               │
│                                                             │
│     Create your first AI video in minutes                   │
│     Just paste your script and let AI do the rest           │
│                                                             │
│          ┌─────────────────────────────┐                    │
│          │  ➕ Create First Project    │                    │
│          └─────────────────────────────┘                    │
└─────────────────────────────────────────────────────────────┘
```

### 2.5 Project Management

**Project States:**

| State | Description | User Actions |
|-------|-------------|--------------|
| **Draft** | Breakdown complete, no videos generated | Edit, Delete, Continue |
| **In Progress** | Some shots generated | Continue, Export partial, Delete |
| **Completed** | All shots generated | Export, Duplicate, Archive, Delete |
| **Archived** | User archived project | Restore, Delete permanently |

**User Capabilities:**

✅ **Save Drafts** - Projects auto-save as user works  
✅ **Duplicate/Clone** - Copy project to create variations  
✅ **Delete** - Soft delete (can restore from archived)  
❌ **Share** - Not in MVP (future team feature)

### 2.6 Credit System

**Credit Economy:**

```yaml
new_user_credits: 0 (no free trial)

credit_packages:
  - price_usd: 5
    credits: 250
  - price_usd: 20
    credits: 1000
  - price_usd: 50
    credits: 3000

minimum_purchase: $5 USD per 30 days

credit_costs:
  script_breakdown: 10 credits
  audio_per_shot: 2 credits
  video_per_shot: 50 credits
  regeneration: Same as original (no discount in MVP)

example_project_cost:
  script_breakdown: 10
  audio_30_shots: 60 (30 × 2)
  video_30_shots: 1500 (30 × 50)
  total: 1570 credits (~$31.40 USD for 50-credit package)
```

**Credit Deduction Flow:**

1. User clicks "Generate" on a shot
2. **Immediately** deduct credits (before generation starts)
3. Update `profiles.credit_balance`
4. Insert record into `credit_transactions`
5. Update `projects.total_credits_used`
6. If generation **fails**: Trigger refund process
7. Credits restored to user balance

**Low Credit Warnings:**

```
Threshold: Admin-configurable (default 100 credits)

Warning Display:
┌─────────────────────────────────────────────────────────────┐
│ ⚠️ Low Credits Warning                                      │
│ You have 85 credits remaining.                              │
│ Add more credits to continue generating videos.             │
│ [Buy Credits]                                               │
└─────────────────────────────────────────────────────────────┘

Hard Block (0 credits):
┌─────────────────────────────────────────────────────────────┐
│ ❌ Insufficient Credits                                     │
│ You need 50 credits but only have 0.                        │
│ Purchase credits to continue.                               │
│ [Buy Credits Now]                                           │
└─────────────────────────────────────────────────────────────┘
```

**Credit Transaction Log:**

Users can view full history in Settings → Billing:

| Date | Action | Amount | Previous | New | Reason |
|------|--------|--------|----------|-----|--------|
| Jan 20, 10:30 | Deduction | -50 | 230 | 180 | Video generation - Shot #5 |
| Jan 20, 10:28 | Deduction | -2 | 232 | 230 | Audio generation - Shot #5 |
| Jan 20, 09:15 | Purchase | +250 | 0 | 250 | Payment $5 via Wave |
| Jan 20, 09:00 | Deduction | -10 | 10 | 0 | Script breakdown - Project "Test" |

### 2.7 User Permissions & Roles

**Role Matrix:**

| Feature | Regular User | Super Admin |
|---------|-------------|-------------|
| Create projects | ✅ | ✅ |
| Generate videos | ✅ | ✅ |
| View own projects | ✅ | ✅ |
| View all users | ❌ | ✅ |
| View all projects | ❌ | ✅ |
| Add/remove credits | ❌ | ✅ |
| Suspend users | ❌ | ✅ |
| Edit platform settings | ❌ | ✅ |
| View n8n jobs | ❌ | ✅ |
| Archive any project | ❌ | ✅ |
| View analytics | Own only | All |

---

## 3. FEATURES & REQUIREMENTS

### 3.1 Script Breakdown Engine

#### 3.1.1 Input Handling

**Specifications:**
- **Max Script Length:** 3 minutes of spoken content (~450-500 words)
- **Input Format:** Plain text only (HTML/Markdown stripped)
- **Character Limit:** ~5,000 characters
- **Validation:** 
  - Reject empty scripts
  - Reject scripts under 50 characters
  - Strip special characters that could break AI parsing

**User Experience:**
```
┌─────────────────────────────────────────────────────────────┐
│ Paste Your Script                                           │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │                                                         │ │
│ │  Welcome to our coffee shop tutorial. Today we'll      │ │
│ │  show you how to make the perfect espresso...          │ │
│ │                                                         │ │
│ │                                                         │ │
│ │                                                         │ │
│ │                                                         │ │
│ └─────────────────────────────────────────────────────────┘ │
│ Characters: 487 / 5,000                                     │
│ Estimated: ~30 shots, ~1,570 credits                        │
│                                                             │
│ ✅ Can user edit script after breakdown? YES               │
│ (Edits to script text in production table)                 │
└─────────────────────────────────────────────────────────────┘
```

#### 3.1.2 AI Segmentation Logic

**Target Shot Duration:** 2-8 seconds per shot

**AI Decision Criteria:**
1. **Scene Changes:** Detect topic shifts, new actions
2. **Narration Pauses:** Natural breathing points, punctuation
3. **Sentence Boundaries:** Don't break mid-sentence
4. **Visual Coherence:** Each shot should represent a single visual idea
5. **Optimal Length:** Prefer 6-8s shots, allow 2s for transitions

**AI Prompt to n8n Workflow:**
```
You are a video production assistant. Break this script into optimal segments for AI video generation.

Rules:
- Each segment must be 2-8 seconds long
- Prefer 6-8 second segments
- Break at natural pauses, scene changes, or sentence boundaries
- Each segment should represent ONE visual idea
- Consider shot variety (wide, close-up, POV)

Script: {user_script}
AI Budget: {ai_budget_percentage}%

Return JSON array of segments with:
- shot_number
- script_text
- duration_seconds
- shot_type (ai_generated or stock_footage)
- 3 camera angle prompts with categories
```

**Segment Adjustment:**
- ❌ Users CANNOT manually adjust segment boundaries in MVP
- ✅ Users CAN edit the script text for each segment
- ✅ Future version: Draggable timeline to merge/split

#### 3.1.3 Prompt Generation

**For Each Segment, AI Generates 3 Prompts:**

**Example Segment:**
```
Script Text: "The coffee beans are roasted at 200 degrees"
Duration: 8 seconds
```

**Generated Prompts:**
```json
{
  "ai_prompt_1": "Close-up of coffee beans in industrial roaster, warm amber lighting, steam rising, shallow depth of field",
  "shot_category_1": "close_up",
  
  "ai_prompt_2": "Wide shot of coffee roastery floor, worker monitoring temperature gauge at 200°C, industrial aesthetic",
  "shot_category_2": "wide_shot",
  
  "ai_prompt_3": "POV from inside roaster drum, coffee beans tumbling, dramatic low angle, motion blur",
  "shot_category_3": "pov"
}
```

**Shot Categories (Enum):**
- `pov` - Point of view
- `close_up` - Close-up shot
- `extreme_close_up` - Extreme close-up
- `medium_shot` - Medium shot
- `wide_shot` - Wide shot
- `off_shoulder` - Over-the-shoulder
- `aerial` - Aerial/drone view
- `low_angle` - Low angle
- `high_angle` - High angle

#### 3.1.4 Stock vs AI Recommendation

**AI Budget System:**

User sets **AI Budget** slider: 20% to 100%

**Decision Logic:**
```
If AI Budget = 80%:
  → 80% of shots use AI generation
  → 20% use stock footage

AI evaluates each segment:
- Generic/common scenes → Recommend stock
  Example: "office desk," "city street"
  
- Specific/unique scenes → Recommend AI
  Example: "purple robot dancing in rain"
  
- Complex/expensive shots → Recommend stock if budget < 60%
  Example: "aerial view of Manhattan"
```

**Stock Footage Hint:**
For stock shots, AI provides search keywords:
```json
{
  "shot_type": "stock_footage",
  "stock_search_hint": "coffee roasting beans industrial"
}
```

User can then search Pexels/Unsplash with those keywords.

**Override Capability:**
- ❌ Users CANNOT override AI recommendation in MVP
- ✅ Future: Toggle button to switch between AI/Stock

### 3.2 Production Table

#### 3.2.1 Table Layout & Columns

**Production Table Structure:**

```
┌──┬──────┬─────────┬──────────────┬──────────────┬──────────┬─────────┐
│☑│ Shot │Duration │ Script       │ AI Prompt    │ Generate │ Preview │
│ │  #   │         │ Text         │ (Select ▼)   │  Button  │         │
├──┼──────┼─────────┼──────────────┼──────────────┼──────────┼─────────┤
│☑│  1   │  6s     │ Welcome to...│ ● Close-up   │  [🎬]    │  [▶️]   │
│ │      │         │              │   Wide shot  │          │  [🔊]   │
│ │      │         │              │   POV        │ Status:  │         │
│ │      │         │              │              │ ✅ Done   │         │
├──┼──────┼─────────┼──────────────┼──────────────┼──────────┼─────────┤
│☑│  2   │  8s     │ The coffee...│ [Select ▼]   │  [🎬]    │  [⏸]   │
│ │      │         │              │              │          │  [🔊]   │
│ │      │         │              │              │Generating│         │
│ │      │         │              │              │ ⏳ 45s   │         │
└──┴──────┴─────────┴──────────────┴──────────────┴──────────┴─────────┘
```

**Column Specifications:**

| Column | Description | Editable | Sortable |
|--------|-------------|----------|----------|
| Checkbox | Bulk selection | Yes | No |
| Shot # | Sequential number | No | Yes |
| Duration | 2-8 seconds | No | Yes |
| Script Text | Narration for this shot | Yes (inline edit) | No |
| AI Prompt | Dropdown with 3 options | Yes (select one) | No |
| Generate | Button + status indicator | Click to trigger | No |
| Preview | Audio/Video players | No | No |

#### 3.2.2 Table Interactions

**User Capabilities:**

✅ **Add Shots Manually**
- Button: "+ Add Shot" at bottom of table
- Opens modal to enter script text, duration, custom prompt

❌ **Drag-to-Reorder** (Not in MVP)

❌ **Delete Shots** (Not in MVP)

✅ **Replace Shots**
- User can edit script text directly in table
- User can regenerate with different prompt selection

✅ **Bulk Select & Generate**
- Checkboxes in first column
- "Bulk Generate" button at top
- Generates audio + video for all selected shots simultaneously

**Inline Editing:**
```
Click on script text cell → Becomes editable textarea
Edit text → Press Enter or click outside to save
Auto-saves to database (optimistic UI update)
```

#### 3.2.3 Generation Process

**User Clicks "Generate" on Shot #5:**

1. **Pre-Flight Check** (Client-Side):
   ```javascript
   // Check credits
   const requiredCredits = 2 (audio) + 50 (video) = 52
   if (userCredits < requiredCredits) {
     showError("Insufficient credits")
     return
   }
   
   // Check storage
   if (userStorageUsed >= 1GB) {
     showError("Storage quota exceeded")
     return
   }
   ```

2. **Trigger n8n Webhooks:**
   ```javascript
   // Parallel requests
   const [audioResponse, videoResponse] = await Promise.all([
     fetch('https://n8n.jelika.app/webhook/generate-audio', {
       method: 'POST',
       headers: { 'X-API-Key': n8nApiKey },
       body: JSON.stringify({
         shot_id: 'uuid',
         script_text: 'Welcome to...',
         voice_id: 'elevenlabs_voice_id',
         voice_settings: { speed: 1.0, stability: 0.75 }
       })
     }),
     fetch('https://n8n.jelika.app/webhook/generate-video', {
       method: 'POST',
       headers: { 'X-API-Key': n8nApiKey },
       body: JSON.stringify({
         shot_id: 'uuid',
         prompt: 'Close-up of coffee beans...',
         duration_seconds: 6,
         aspect_ratio: '16:9',
         resolution: '1080p'
       })
     })
   ])
   ```

3. **Update Database:**
   ```sql
   UPDATE shots
   SET generation_status = 'generating',
       updated_at = NOW(),
       updated_by = auth.uid()
   WHERE id = 'shot_uuid';
   ```

4. **Supabase Realtime Updates UI:**
   ```javascript
   // Vue component subscribes to Realtime
   supabase
     .channel('shots')
     .on('postgres_changes', {
       event: 'UPDATE',
       schema: 'public',
       table: 'shots',
       filter: `id=eq.${shotId}`
     }, (payload) => {
       // Update UI with new status
       if (payload.new.generation_status === 'completed') {
         // Show preview buttons
       }
     })
     .subscribe()
   ```

5. **Vue App Polls n8n for Completion:**
   ```javascript
   // Poll every 10 seconds
   const pollInterval = setInterval(async () => {
     const shot = await supabase
       .from('shots')
       .select('generation_status, video_file_url, audio_file_url')
       .eq('id', shotId)
       .single()
     
     if (shot.generation_status === 'completed') {
       clearInterval(pollInterval)
       // n8n returned base64, Vue uploads to Supabase Storage
       await uploadMediaToStorage(shot)
     }
   }, 10000) // Admin-configurable timeout
   ```

6. **Upload Media to Supabase Storage:**
   ```javascript
   // Decode base64 from n8n
   const audioBlob = base64ToBlob(audioResponse.data.audio_base64)
   const videoBlob = base64ToBlob(videoResponse.data.video_base64)
   
   // Upload to Supabase Storage
   await supabase.storage
     .from('generated-media')
     .upload(`${userId}/shot_${shotNumber}_audio.mp3`, audioBlob)
   
   await supabase.storage
     .from('generated-media')
     .upload(`${userId}/shot_${shotNumber}_video.mp4`, videoBlob)
   
   // Update shots table with URLs
   await supabase
     .from('shots')
     .update({
       audio_file_url: audioPublicUrl,
       video_file_url: videoPublicUrl,
       generation_status: 'completed'
     })
     .eq('id', shotId)
   ```

**Generation Time Estimates:**
- Audio (ElevenLabs): 2-5 seconds
- Video (Veo 3): 60-120 seconds (admin-configurable timeout)
- Total per shot: ~90-150 seconds

**Progress Indicators:**

```
┌─────────────────────────────────────────┐
│ Generating... ⏳ 45s                    │
│ ████████████░░░░░░░░░░░░░ 60%          │
│                                         │
│ ✅ Audio: Complete (4s)                 │
│ 🔄 Video: Processing... (est. 75s left) │
└─────────────────────────────────────────┘
```

#### 3.2.4 Preview & Review

**Audio Preview:**
- Click 🔊 icon in table row
- Inline HTML5 audio player appears
- Waveform visualization (future enhancement)

```html
<audio controls>
  <source src="{audio_file_url}" type="audio/mpeg">
</audio>
```

**Video Preview:**
- Click ▶️ icon in table row
- Modal popup with larger video player
- Shows video with aspect ratio maintained

```
┌─────────────────────────────────────────┐
│  Shot #5 Preview                  [✕]   │
├─────────────────────────────────────────┤
│                                         │
│        [16:9 Video Player]              │
│                                         │
│  ◀️  ⏸  ▶️  🔊 ───────●──── 0:06      │
│                                         │
│  Script: "Welcome to our coffee..."     │
│  Prompt: Close-up of coffee beans...    │
│                                         │
│  [Regenerate] [Download]                │
└─────────────────────────────────────────┘
```

**Combined Preview (Audio + Video Synced):**
✅ **YES - Needed for MVP**

Before export, user can preview full project:

```
┌─────────────────────────────────────────────────────────────┐
│  Project Preview: "Coffee Tutorial"                   [✕]   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│              [Video Player - 16:9]                          │
│              Shot 5 of 30                                   │
│                                                             │
│  ◀️  ⏸  ▶️  🔊 ─────────●────────────── 0:35 / 2:45       │
│                                                             │
│  Timeline (Filmstrip):                                      │
│  ┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐                       │
│  │1 │2 │3 │4 │●5│6 │7 │8 │9 │10│..│                       │
│  └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘                       │
│                                                             │
│  [← Previous Shot]  [Next Shot →]  [Export Project]        │
└─────────────────────────────────────────────────────────────┘
```

### 3.3 Audio Generation (ElevenLabs)

#### 3.3.1 Voice Selection

**User Provides API Token:**

```
Settings → Integrations → ElevenLabs
┌─────────────────────────────────────────┐
│ ElevenLabs API Key                      │
│ [••••••••••••••••] [Show] [Update]     │
│                                         │
│ Status: ✅ Connected                    │
│ Available Voices: 3                     │
│                                         │
│ [Test Connection]                       │
└─────────────────────────────────────────┘
```

**Voice Loading:**
When user adds API key, Vue app calls:
```javascript
const voices = await fetch('https://api.elevenlabs.io/v1/voices', {
  headers: { 'xi-api-key': userApiKey }
})
```

**Voice Selection UI:**

Per-project or per-shot:
```
┌─────────────────────────────────────────┐
│ Select Voice                            │
│ ○ Rachel (American, Female, Energetic)  │
│ ● Adam (American, Male, Deep)           │
│ ○ Bella (British, Female, Calm)         │
└─────────────────────────────────────────┘
```

**Voice Limit for MVP:** 3 voices displayed (user's first 3 from ElevenLabs)

#### 3.3.2 Audio Settings

**Per-Shot Voice Settings (JSONB Column):**

```json
{
  "voice_id": "elevenlabs_voice_id_here",
  "speed": 1.0,
  "stability": 0.75,
  "clarity": 0.85,
  "emotion": "neutral"
}
```

**UI Controls:**

```
┌─────────────────────────────────────────┐
│ Voice Settings (Advanced)               │
│                                         │
│ Speed: 1.0                              │
│ ├───●────────┤ 0.5 ↔ 2.0               │
│                                         │
│ Stability: 0.75                         │
│ ├──────●─────┤ 0.0 ↔ 1.0               │
│                                         │
│ Clarity: 0.85                           │
│ ├───────●────┤ 0.0 ↔ 1.0               │
│                                         │
│ Emotion: [Dropdown ▼]                   │
│   ● Neutral                             │
│   ○ Excited                             │
│   ○ Sad                                 │
│   ○ Angry                               │
│                                         │
│ [Apply to All Shots] [Reset to Default] │
└─────────────────────────────────────────┘
```

#### 3.3.3 Audio Editing

**Regeneration:**
✅ User can regenerate audio with different settings
✅ Costs same credits (no discount in MVP)
✅ Previous audio file replaced (not deleted from storage)

**Custom Upload:**
✅ User can upload their own MP3 file instead of generating

```
┌─────────────────────────────────────────┐
│ Shot #5 Audio Options                   │
│                                         │
│ ○ Generate with ElevenLabs (2 credits) │
│ ● Upload Custom Audio File              │
│                                         │
│ [Choose File] custom_audio.mp3          │
│ Max size: 2MB (admin-configurable)      │
│                                         │
│ [Upload]                                │
└─────────────────────────────────────────┘
```

### 3.4 Video Generation (n8n + Veo 3)

#### 3.4.1 Generation Options

**3 Prompt Alternatives:**

User sees 3 different prompts, selects ONE to generate:

```
┌─────────────────────────────────────────────────────────────┐
│ Select Camera Angle for Shot #5                             │
├─────────────────────────────────────────────────────────────┤
│ ○ Prompt 1: Close-up (close_up)                            │
│   "Close-up of coffee beans in roaster, warm lighting..."   │
│                                                             │
│ ● Prompt 2: Wide Shot (wide_shot)                          │
│   "Wide shot of coffee roastery floor, worker at gauge..."  │
│                                                             │
│ ○ Prompt 3: POV (pov)                                      │
│   "POV from inside roaster, beans tumbling, dramatic..."    │
└─────────────────────────────────────────────────────────────┘
```

❌ **System does NOT generate all 3 videos** (too expensive)  
✅ **User picks 1 prompt, only that one is generated**

#### 3.4.2 Video Quality Settings

**Resolution Options (Enum):**
- `720p` - 1280×720
- `1080p` - 1920×1080 (default)
- `4k` - 3840×2160

**Aspect Ratio Options (Enum):**
- `16:9` - Landscape (YouTube, horizontal)
- `9:16` - Portrait (TikTok, Instagram Reels)
- `1:1` - Square (Instagram posts)
- `4:5` - Vertical (Instagram Stories)

**Set at Project Level:**
```
Project Settings:
- Resolution: 1080p
- Aspect Ratio: 16:9

All shots in project inherit these settings.
```

#### 3.4.3 Generation Limits

**Credit-Based Limits:**
✅ **Unlimited generations** as long as user has credits
✅ **No daily/hourly rate limits in MVP**
✅ **Admin can configure rate limits** in `admin_settings.platform_settings`

**Abuse Prevention (Future):**
```json
{
  "rate_limit_generations_per_hour": 100,
  "rate_limit_enabled": false
}
```

**Timeout Handling:**
- Default timeout: 180 seconds (3 minutes)
- Admin-configurable in `platform_settings`
- If timeout exceeded: Mark as failed, refund credits

**Retry Logic:**
- If generation fails: Automatic retry (2-5 minutes)
- Max retries: 3 attempts
- After 3 failures: Mark as permanently failed, show error to user

### 3.5 Export System

#### 3.5.1 Export Options

**MVP Export Deliverables:**

✅ **Individual Clips Only** (not stitched video)

ZIP file structure:
```
project_coffee-tutorial_export_2026-01-20.zip
│
├── shot_01_video.mp4
├── shot_01_audio.mp3
├── shot_02_video.mp4
├── shot_02_audio.mp3
├── ...
├── shot_30_video.mp4
└── shot_30_audio.mp3

Total: 60 files (30 shots × 2 files each)
```

❌ **Stitched Video** (Future Version)
❌ **Metadata JSON** (Future Version)

#### 3.5.2 File Naming Convention

**Pattern:**
```
shot_{shot_number:02d}_{media_type}.{extension}

Examples:
- shot_01_video.mp4
- shot_01_audio.mp3
- shot_15_video.mp4
- shot_15_audio.mp3
```

**Padding:** Shot numbers zero-padded to 2 digits (01, 02, ... 99)

#### 3.5.3 Export Processing

**User Flow:**

1. User clicks "Export Project" button
2. **Client-Side ZIP Creation:**
   ```javascript
   import JSZip from 'jszip'
   
   const zip = new JSZip()
   
   // Download all files from Supabase Storage
   for (const shot of shots) {
     const videoBlob = await fetch(shot.video_file_url).then(r => r.blob())
     const audioBlob = await fetch(shot.audio_file_url).then(r => r.blob())
     
     zip.file(`shot_${shot.shot_number.toString().padStart(2, '0')}_video.mp4`, videoBlob)
     zip.file(`shot_${shot.shot_number.toString().padStart(2, '0')}_audio.mp3`, audioBlob)
   }
   
   // Generate ZIP
   const zipBlob = await zip.generateAsync({ type: 'blob' })
   
   // Trigger download
   const url = URL.createObjectURL(zipBlob)
   const a = document.createElement('a')
   a.href = url
   a.download = `project_${projectSlug}_export_${Date.now()}.zip`
   a.click()
   ```

3. **Background Queue** (Optional Enhancement):
   - For large projects (50+ shots), queue export
   - Show progress: "Creating export... 45%"
   - Email notification when ready

4. **Email Notification:**
   ```
   Subject: Your Jelika Export is Ready!
   
   Hi Elhadji,
   
   Your export for "Coffee Shop Tutorial" is ready to download.
   
   Project: Coffee Shop Tutorial
   Shots: 30
   Total Size: 450 MB
   
   Download Link: [Download ZIP]
   (Link expires in 3 days)
   
   Thanks,
   Jelika Team
   ```

5. **Storage Duration:**
   - Export files stored for **3 days**
   - After 3 days: Automatic deletion via scheduled job
   - User notified 1 day before expiration

#### 3.5.4 File Compression

**Video Compression:**

Default Veo 3 output: ~10MB per 8-second clip  
30 clips = 300MB video + 30MB audio = **330MB total**

**Compression Strategy:**

Use **FFmpeg** for video optimization:
```bash
# Compress without quality loss
ffmpeg -i input.mp4 \
  -c:v libx264 \
  -crf 23 \
  -preset medium \
  -c:a aac \
  -b:a 128k \
  output.mp4
```

**Expected Savings:** 30-40% file size reduction  
**Final ZIP Size:** ~200-250MB for 30-shot project

### 3.6 Project Management

#### 3.6.1 Project Metadata

**Stored Fields:**

```yaml
project:
  id: uuid
  user_id: uuid (foreign key)
  name: "Coffee Shop Tutorial" (user-defined)
  slug: "elhadji-coffee-shop-tutorial-1" (auto-generated)
  description: "Step-by-step guide to making espresso" (optional)
  script: "Welcome to our coffee shop..." (original full script)
  
  # Video Settings
  ai_budget_percentage: 80 (20-100)
  target_aspect_ratio: '16:9'
  target_resolution: '1080p'
  voiceover_language: 'en-US'
  project_language: 'en-US'
  
  # Avatar/Environment (Future)
  avatar_id: uuid (nullable)
  wardrobe_id: uuid (nullable)
  environment_id: uuid (nullable)
  
  # Status & Metrics
  status: 'completed' (enum: draft | in_progress | completed | archived)
  total_shots: 30
  total_credits_used: 1570
  
  # Timestamps
  created_at: timestamp
  updated_at: timestamp
  created_by: uuid (auth.uid())
  updated_by: uuid (auth.uid())
```

#### 3.6.2 Project Slug Generation

**Pattern:**
```
{username}-{project-name}-{incremental-number}

Examples:
- elhadji-coffee-shop-tutorial-1
- elhadji-coffee-shop-tutorial-2 (if duplicate name)
- elhadji-my-first-podcast-1
```

**Algorithm:**
```javascript
async function generateProjectSlug(userId, projectName) {
  const user = await getUser(userId)
  const username = user.email.split('@')[0] // "elhadji@example.com" → "elhadji"
  
  const slugBase = `${username}-${slugify(projectName)}`
  
  // Check for existing slugs
  const existingCount = await db
    .from('projects')
    .select('slug')
    .like('slug', `${slugBase}%`)
    .count()
  
  const incrementalNumber = existingCount + 1
  
  return `${slugBase}-${incrementalNumber}`
}

function slugify(text) {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
}
```

**Auto-Generated:** Yes, not user-editable

#### 3.6.3 Project States & Transitions

```
┌─────────┐
│  DRAFT  │ ← Script breakdown complete, no videos yet
└────┬────┘
     │ User generates first shot
     ↓
┌──────────────┐
│ IN_PROGRESS  │ ← Some shots generated
└──────┬───────┘
       │ All shots generated
       ↓
┌──────────┐
│COMPLETED │ ← All shots done, ready to export
└────┬─────┘
     │ User archives
     ↓
┌──────────┐
│ ARCHIVED │ ← Hidden from main list, can restore
└──────────┘
```

**State-Based Actions:**

| State | Available Actions |
|-------|------------------|
| Draft | Edit, Delete, Continue Editing |
| In Progress | Continue, Export Partial, Delete |
| Completed | View, Export, Duplicate, Archive, Delete |
| Archived | Restore, Delete Permanently |

---

## 4. TECHNICAL ARCHITECTURE

### 4.1 System Architecture Diagram

```
┌───────────────────────────────────────────────────────────────┐
│                    CLIENT LAYER (Browser)                     │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │  Vue 3 SPA + Vite                                       │  │
│  │  - Pinia (State Management)                             │  │
│  │  - Vue Router (Routing)                                 │  │
│  │  - TailwindCSS (Styling)                                │  │
│  │  - Supabase Client SDK                                  │  │
│  └─────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
                            ↕ HTTPS
┌───────────────────────────────────────────────────────────────┐
│                  APPLICATION LAYER (Supabase)                 │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │  Supabase Auth                                          │  │
│  │  - Email/Password                                       │  │
│  │  - Google OAuth                                         │  │
│  │  - Session Management                                   │  │
│  └─────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │  Supabase Database (PostgreSQL 15)                      │  │
│  │  - Row Level Security (RLS)                             │  │
│  │  - Triggers & Functions                                 │  │
│  │  - Real-time Subscriptions                              │  │
│  └─────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │  Supabase Storage                                       │  │
│  │  - user-uploads bucket                                  │  │
│  │  - generated-media bucket                               │  │
│  │  - user-assets bucket (avatars, profiles)               │  │
│  └─────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
                            ↕ Webhooks
┌───────────────────────────────────────────────────────────────┐
│               AUTOMATION LAYER (n8n Self-Hosted)              │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │  n8n Workflows (7 total)                                │  │
│  │  1. Script Breakdown (GPT/Claude)                       │  │
│  │  2. Prompt Generation                                   │  │
│  │  3. Audio Generation (ElevenLabs)                       │  │
│  │  4. Video Generation (Veo 3)                            │  │
│  │  5. Avatar Creation (Future)                            │  │
│  │  6. Environment Creation (Future)                       │  │
│  │  7. Payment Webhooks (Wave/Orange)                      │  │
│  └─────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
                            ↕ APIs
┌───────────────────────────────────────────────────────────────┐
│                   EXTERNAL SERVICES LAYER                     │
│  ┌──────────────┬──────────────┬──────────────┬────────────┐  │
│  │ ElevenLabs   │  Google      │  SendGrid    │  Sentry    │  │
│  │ Audio API    │  Veo 3 API   │  Email API   │  Logging   │  │
│  └──────────────┴──────────────┴──────────────┴────────────┘  │
│  ┌──────────────┬──────────────┬──────────────┬────────────┐  │
│  │ Wave         │  Orange      │  Cloudflare  │  S3        │  │
│  │ Payment API  │  Money API   │  DNS/CDN     │  Backups   │  │
│  └──────────────┴──────────────┴──────────────┴────────────┘  │
└───────────────────────────────────────────────────────────────┘
```

### 4.2 n8n Workflow Architecture

#### 4.2.1 Workflow List

**7 n8n Workflows:**

1. **Script Breakdown Workflow**
   - Trigger: Webhook from Vue app
   - AI Model: Admin-configured (GPT-4/Claude/Gemini)
   - Output: JSON array of segments

2. **Prompt Generation Workflow** (merged with #1 for efficiency)
   - Generates 3 camera angle prompts per segment
   - Returns prompt text + shot category

3. **Audio Generation Workflow**
   - Trigger: Webhook per shot
   - Calls ElevenLabs API with user's API key
   - Returns: Base64 audio data

4. **Video Generation Workflow**
   - Trigger: Webhook per shot
   - Calls Veo 3 API
   - Returns: Base64 video data + thumbnail

5. **Export/Compilation Workflow** (NOT NEEDED - client-side ZIP)

6. **Avatar Creation Workflow** (Future)
   - Processes reference photos
   - Generates avatar model

7. **Environment Creation Workflow** (Future)
   - Processes reference images
   - Creates 3D environment

8. **Payment Webhook Handler**
   - Wave payment webhook → Insert transaction
   - Orange Money webhook → Insert transaction

#### 4.2.2 Webhook Authentication

**API Key Strategy:**

```yaml
n8n_webhook_security:
  method: API Key in Header
  header_name: X-API-Key
  key_storage: Environment variable on VM
  
vue_app_calls:
  headers:
    X-API-Key: ${N8N_API_KEY}
    Content-Type: application/json
```

**Example Request:**
```javascript
await fetch('https://n8n.jelika.app/webhook/generate-audio', {
  method: 'POST',
  headers: {
    'X-API-Key': process.env.N8N_API_KEY,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({ ... })
})
```

#### 4.2.3 Webhook Response Format

**Standard Response Structure:**

```json
{
  "success": true | false,
  "data": { ... },
  "error": null | { code, message, details },
  "execution_id": "n8n-exec-123456"
}
```

**Success Example:**
```json
{
  "success": true,
  "data": {
    "segments": [
      {
        "shot_number": 1,
        "script_text": "Welcome to our coffee shop",
        "duration_seconds": 6,
        "shot_type": "ai_generated",
        "ai_prompts": [
          { "prompt": "Close-up...", "category": "close_up" },
          { "prompt": "Wide shot...", "category": "wide_shot" },
          { "prompt": "POV...", "category": "pov" }
        ]
      }
    ]
  },
  "error": null,
  "execution_id": "n8n-exec-20260120-001"
}
```

**Error Example:**
```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "ELEVENLABS_API_ERROR",
    "message": "Invalid API key provided",
    "details": {
      "provider": "ElevenLabs",
      "status_code": 401
    }
  },
  "execution_id": "n8n-exec-20260120-002"
}
```

### 4.3 Data Flow Patterns

#### 4.3.1 Script Breakdown Flow

```
┌──────────────┐
│  Vue App     │
│  User pastes │
│  script      │
└──────┬───────┘
       │ POST /webhook/script-breakdown
       ↓
┌──────────────┐
│  n8n         │
│  Workflow #1 │
└──────┬───────┘
       │ Call AI API (GPT-4/Claude)
       ↓
┌──────────────┐
│  AI Model    │
│  Segments    │
│  script      │
└──────┬───────┘
       │ Return JSON
       ↓
┌──────────────┐
│  n8n         │
│  Returns to  │
│  Vue app     │
└──────┬───────┘
       │ JSON response
       ↓
┌──────────────┐
│  Vue App     │
│  Inserts     │
│  shots into  │
│  Supabase    │
└──────────────┘
```

#### 4.3.2 Audio/Video Generation Flow

```
┌──────────────┐
│  Vue App     │
│  User clicks │
│  "Generate"  │
└──────┬───────┘
       │ 1. Deduct credits immediately
       │ 2. Update shot.generation_status = 'generating'
       ↓
┌──────────────┐
│  Supabase    │
│  Database    │
│  Trigger     │
└──────┬───────┘
       │ 3. Credit transaction inserted
       ↓
┌──────────────┐
│  Vue App     │
│  Parallel    │
│  webhook     │
│  calls       │
└──────┬───────┘
       │ 4. POST /webhook/generate-audio
       │ 5. POST /webhook/generate-video
       ↓
┌──────────────┐
│  n8n         │
│  Workflows   │
│  3 & 4       │
└──────┬───────┘
       │ 6. Call ElevenLabs API
       │ 7. Call Veo 3 API
       ↓
┌──────────────┐
│  External    │
│  APIs        │
└──────┬───────┘
       │ 8. Return base64 data
       ↓
┌──────────────┐
│  n8n         │
│  Returns     │
│  base64      │
└──────┬───────┘
       │ 9. JSON response to Vue
       ↓
┌──────────────┐
│  Vue App     │
│  Uploads to  │
│  Supabase    │
│  Storage     │
└──────┬───────┘
       │ 10. Get public URLs
       ↓
┌──────────────┐
│  Supabase    │
│  Update shot │
│  with URLs   │
└──────┬───────┘
       │ 11. generation_status = 'completed'
       ↓
┌──────────────┐
│  Realtime    │
│  Update UI   │
└──────────────┘
```

#### 4.3.3 Real-time Updates (Supabase)

**Subscription Pattern:**

```javascript
// Vue component setup
import { supabase } from '@/lib/supabase'

// Subscribe to shots table changes
const channel = supabase
  .channel('production-table')
  .on(
    'postgres_changes',
    {
      event: 'UPDATE',
      schema: 'public',
      table: 'shots',
      filter: `project_id=eq.${projectId}`
    },
    (payload) => {
      console.log('Shot updated:', payload)
      
      // Update local state
      const updatedShot = payload.new
      updateShotInState(updatedShot)
      
      // If generation completed, show notification
      if (updatedShot.generation_status === 'completed') {
        showToast('Shot generated successfully!')
      }
    }
  )
  .subscribe()

// Cleanup on unmount
onUnmounted(() => {
  channel.unsubscribe()
})
```

**Polling Fallback:**

If Realtime connection drops:
```javascript
let pollInterval

function startPolling() {
  pollInterval = setInterval(async () => {
    const { data } = await supabase
      .from('shots')
      .select('*')
      .eq('project_id', projectId)
      .in('generation_status', ['generating', 'queued'])
    
    // Update UI with latest data
    updateShotsInState(data)
  }, 10000) // Every 10 seconds
}

// Stop polling when Realtime reconnects
supabase.channel('system').on('system', { event: '*' }, (payload) => {
  if (payload.status === 'SUBSCRIBED') {
    clearInterval(pollInterval)
  }
})
```

### 4.4 Supabase Configuration

#### 4.4.1 Authentication Setup

**Auth Providers:**
```yaml
email_password:
  enabled: true
  email_verification: required
  password_requirements:
    min_length: 8
    require_uppercase: true
    require_number: true

google_oauth:
  enabled: true
  provider: google
  client_id: from_google_console
  client_secret: from_google_console
  redirect_url: https://app.jelika.app/auth/callback
```

**Password Reset Flow:**
```
1. User clicks "Forgot Password"
2. Enters email
3. Supabase sends reset link
4. User clicks link → Redirected to reset page
5. User enters new password
6. Success → Redirect to login
```

#### 4.4.2 Storage Buckets

**3 Buckets:**

```yaml
buckets:
  - name: user-uploads
    public: false
    file_size_limit: 2MB (admin-configurable)
    allowed_mime_types:
      - audio/mpeg
      - audio/mp3
      - image/jpeg
      - image/png
    rls_policies:
      - Users can upload to their own folder
      - Users can read their own files
      
  - name: generated-media
    public: true (read-only)
    file_size_limit: 50MB
    allowed_mime_types:
      - video/mp4
      - audio/mpeg
    rls_policies:
      - Users can upload to their own folder
      - Users can read their own files
      - Public read access via signed URLs
      
  - name: user-assets
    public: false
    file_size_limit: 5MB
    allowed_mime_types:
      - image/jpeg
      - image/png
      - image/webp
    rls_policies:
      - Users can upload avatars/profile pics
      - Public read via signed URLs
```

**Storage Quota:**
- Per-user limit: 1GB
- Tracked in `profiles.total_storage_used`
- Checked before upload

#### 4.4.3 Realtime Configuration

**Enabled Tables:**
```sql
-- Enable realtime for shots table
ALTER PUBLICATION supabase_realtime ADD TABLE shots;

-- Enable realtime for projects table
ALTER PUBLICATION supabase_realtime ADD TABLE projects;

-- Enable realtime for notifications table
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
```

**Realtime Policies:**
```sql
-- Users can only subscribe to their own data
CREATE POLICY "Users can subscribe to own shots"
ON shots FOR SELECT
USING (auth.uid() = (SELECT user_id FROM projects WHERE id = shots.project_id));
```

### 4.5 External API Integration

#### 4.5.1 ElevenLabs Audio API

**User-Provided API Keys:**
- Stored encrypted in `profiles.elevenlabs_api_key`
- Never exposed to client-side
- Passed to n8n workflow server-side

**API Calls:**
```javascript
// n8n workflow
const response = await fetch('https://api.elevenlabs.io/v1/text-to-speech/{voice_id}', {
  method: 'POST',
  headers: {
    'xi-api-key': userApiKey,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    text: scriptText,
    model_id: 'eleven_monolingual_v1',
    voice_settings: {
      stability: 0.75,
      similarity_boost: 0.85,
      speed: 1.0
    }
  })
})

const audioBuffer = await response.arrayBuffer()
const base64Audio = Buffer.from(audioBuffer).toString('base64')

return { audio_base64: base64Audio }
```

#### 4.5.2 Google Veo 3 Video API

**Platform API Key:**
- Stored in n8n environment variables
- Single key for all users

**API Calls:**
```javascript
// n8n workflow
const response = await fetch('https://generativelanguage.googleapis.com/v1/models/veo-2:generateVideo', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${process.env.VEO3_API_KEY}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    prompt: aiPrompt,
    duration_seconds: durationSeconds,
    aspect_ratio: aspectRatio,
    resolution: resolution
  })
})

const videoData = await response.json()
return {
  video_base64: videoData.video,
  thumbnail_base64: videoData.thumbnail
}
```

#### 4.5.3 AI Model for Script Breakdown

**Admin-Configurable:**

Stored in `admin_settings.platform_settings`:
```json
{
  "ai_model_provider": "openai",
  "ai_model_name": "gpt-4-turbo-preview"
}
```

**Supported Providers:**
- OpenAI (GPT-4, GPT-4 Turbo)
- Anthropic (Claude Sonnet 4.5, Claude Opus 4.5)
- Google (Gemini Pro, Gemini Ultra)

**API Call (n8n):**
```javascript
const provider = adminSettings.ai_model_provider
const model = adminSettings.ai_model_name

if (provider === 'openai') {
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: model,
      messages: [{
        role: 'system',
        content: 'You are a video production assistant...'
      }, {
        role: 'user',
        content: `Break this script into segments: ${script}`
      }]
    })
  })
}
```

#### 4.5.4 Payment Provider APIs

**Wave API:**
```javascript
// n8n webhook handler
app.post('/webhook/wave', async (req, res) => {
  const { transaction_id, amount, status, customer_email } = req.body
  
  if (status === 'completed') {
    // Insert payment transaction
    await supabase
      .from('payment_transactions')
      .insert({
        payment_provider: 'wave',
        payment_amount_usd: amount,
        credits_purchased: calculateCredits(amount),
        provider_transaction_id: transaction_id,
        payment_status: 'completed'
      })
    
    // Add credits to user
    const user = await getUserByEmail(customer_email)
    await addCredits(user.id, calculateCredits(amount), 'Payment via Wave')
  }
  
  res.json({ success: true })
})
```

**Orange Money API:**
Similar structure to Wave

#### 4.5.5 SendGrid Email API

**Email Templates:**

1. **Welcome Email** (Supabase handles)
2. **Export Ready Notification:**
```javascript
// n8n workflow after export complete
await sendgrid.send({
  to: user.email,
  from: 'noreply@jelika.app',
  subject: 'Your Jelika Export is Ready!',
  templateId: 'd-xxxxx',
  dynamicTemplateData: {
    user_name: user.full_name,
    project_name: project.name,
    download_url: exportUrl,
    expiry_date: expiryDate
  }
})
```

3. **Low Credits Warning:**
4. **Payment Receipt:**

### 4.6 Error Handling & Monitoring

#### 4.6.1 Sentry Integration

**Vue App Configuration:**
```javascript
// main.js
import * as Sentry from "@sentry/vue"

Sentry.init({
  app,
  dsn: process.env.VITE_SENTRY_DSN,
  environment: process.env.NODE_ENV,
  integrations: [
    new Sentry.BrowserTracing({
      routingInstrumentation: Sentry.vueRouterInstrumentation(router),
    }),
    new Sentry.Replay(),
  ],
  tracesSampleRate: 1.0,
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,
})
```

**Error Capture:**
```javascript
try {
  await generateVideo(shotId)
} catch (error) {
  Sentry.captureException(error, {
    tags: {
      feature: 'video-generation',
      shot_id: shotId
    },
    extra: {
      prompt: shot.ai_prompt_1,
      user_id: userId
    }
  })
  
  showErrorToast('Video generation failed. Our team has been notified.')
}
```

#### 4.6.2 Failed Generation Handling

**Automatic Retry:**
```javascript
async function generateWithRetry(shotId, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      const result = await generateVideo(shotId)
      return result
    } catch (error) {
      if (attempt === maxRetries) {
        // Final failure - refund credits
        await refundCredits(shotId)
        await markAsFailed(shotId, error.message)
        throw error
      }
      
      // Wait before retry (exponential backoff)
      await sleep(2 ** attempt * 1000) // 2s, 4s, 8s
    }
  }
}
```

**Credit Refund Trigger:**
```sql
CREATE OR REPLACE FUNCTION refund_credits_on_failure()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.generation_status = 'failed' AND OLD.generation_status = 'generating' THEN
    -- Refund credits
    INSERT INTO credit_transactions (
      user_id,
      transaction_type,
      amount,
      reason,
      shot_id
    )
    SELECT
      p.user_id,
      'refund',
      NEW.video_credits_used + NEW.audio_credits_used,
      'Refund: Generation failed for Shot #' || NEW.shot_number,
      NEW.id
    FROM projects p
    WHERE p.id = NEW.project_id;
    
    -- Update user balance
    UPDATE profiles
    SET credit_balance = credit_balance + (NEW.video_credits_used + NEW.audio_credits_used)
    WHERE id = (SELECT user_id FROM projects WHERE id = NEW.project_id);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_refund_on_failure
AFTER UPDATE ON shots
FOR EACH ROW
EXECUTE FUNCTION refund_credits_on_failure();
```

#### 4.6.3 Logging Strategy

**Loki for Centralized Logging:**

**Docker Loki Configuration:**
```yaml
# docker-compose.yml
services:
  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
    volumes:
      - loki-data:/loki

  promtail:
    image: grafana/promtail:latest
    volumes:
      - /var/log:/var/log
      - ./promtail-config.yml:/etc/promtail/config.yml
    command: -config.file=/etc/promtail/config.yml
```

**Log Levels:**
- **INFO:** Normal operations (user signup, project created)
- **WARN:** Low credits, approaching storage limit
- **ERROR:** Failed generations, API errors
- **CRITICAL:** Database connection lost, n8n down

**Queryable Logs:**
```
{app="jelika"} |= "generation_failed"
{app="jelika", level="ERROR"}
{app="n8n"} |= "workflow_execution_failed"
```

---

*This README continues with Sections 5-8. See accompanying files:*
- `database/schema.sql` - Complete database schema
- `api/endpoints.md` - API specifications
- `deployment/docker-compose.yml` - Deployment configuration
- `docs/ui-specifications.md` - UI/UX detailed specs

