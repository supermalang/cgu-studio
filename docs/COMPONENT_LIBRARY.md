# Jelika - Component Library

Reusable Vue components for the Jelika platform with usage examples.

---

## 🎯 Component Categories

1. [Common Components](#common-components) - Shared UI elements
2. [Authentication Components](#authentication-components) - Login, signup, etc.
3. [Dashboard Components](#dashboard-components) - Dashboard widgets
4. [Project Components](#project-components) - Project management
5. [Production Components](#production-components) - Video production workflow

---

## Common Components

### AppHeader

**Location:** `src/components/common/AppHeader.vue`

**Description:** Main navigation header with logo, credit balance, and user menu.

**Features:**
- Logo and brand name
- Credit balance display
- User profile dropdown
- Logout functionality
- Admin menu option (for admins)

**Usage:**
```vue
<script setup>
import AppHeader from '@/components/common/AppHeader.vue'
</script>

<template>
  <div class="min-h-screen bg-neutral-50">
    <AppHeader />
    <!-- Page content -->
  </div>
</template>
```

**Props:** None (uses auth store)

---

### Button Component (Planned)

**Location:** `src/components/common/Button.vue` (to be created)

**Recommended Structure:**
```vue
<script setup>
defineProps({
  variant: {
    type: String,
    default: 'primary',
    validator: (value) => ['primary', 'secondary', 'ghost', 'danger'].includes(value)
  },
  size: {
    type: String,
    default: 'md',
    validator: (value) => ['sm', 'md', 'lg'].includes(value)
  },
  loading: Boolean,
  disabled: Boolean
})
</script>

<template>
  <button
    :class="[
      'btn-' + variant,
      size === 'sm' && 'btn-sm',
      size === 'lg' && 'btn-lg'
    ]"
    :disabled="disabled || loading"
  >
    <span v-if="loading" class="loading-spinner mr-2"></span>
    <slot />
  </button>
</template>
```

**Usage:**
```vue
<Button variant="primary" size="lg" :loading="isSubmitting">
  Submit
</Button>
```

---

### Modal Component (Planned)

**Location:** `src/components/common/Modal.vue` (to be created)

**Recommended Structure:**
```vue
<script setup>
const props = defineProps({
  show: Boolean,
  title: String,
  maxWidth: {
    type: String,
    default: 'lg'
  }
})

const emit = defineEmits(['close'])

function closeModal() {
  emit('close')
}
</script>

<template>
  <Transition>
    <div v-if="show" class="modal-overlay" @click.self="closeModal">
      <div class="modal-content animate-fade-in" :class="'max-w-' + maxWidth">
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-2xl font-bold">{{ title }}</h2>
          <button
            @click="closeModal"
            class="text-neutral-500 hover:text-neutral-700"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <slot />

        <div v-if="$slots.footer" class="flex gap-3 justify-end mt-6 pt-4 border-t border-neutral-200">
          <slot name="footer" />
        </div>
      </div>
    </div>
  </Transition>
</template>
```

**Usage:**
```vue
<Modal
  :show="showModal"
  title="Create New Project"
  @close="showModal = false"
>
  <!-- Modal content -->
  <p>Modal body content here</p>

  <!-- Footer buttons -->
  <template #footer>
    <button class="btn-secondary" @click="showModal = false">
      Cancel
    </button>
    <button class="btn-primary" @click="handleSubmit">
      Create
    </button>
  </template>
</Modal>
```

---

### Badge Component (Planned)

**Location:** `src/components/common/Badge.vue` (to be created)

**Recommended Structure:**
```vue
<script setup>
defineProps({
  variant: {
    type: String,
    default: 'neutral',
    validator: (value) => ['primary', 'success', 'error', 'warning', 'neutral'].includes(value)
  }
})
</script>

<template>
  <span :class="'badge-' + variant">
    <slot />
  </span>
</template>
```

**Usage:**
```vue
<Badge variant="success">Active</Badge>
<Badge variant="error">Failed</Badge>
<Badge variant="warning">Pending</Badge>
```

---

### StatusBadge Component (Planned)

**Location:** `src/components/common/StatusBadge.vue` (to be created)

**Description:** Generation status indicator with icons and animations.

**Recommended Structure:**
```vue
<script setup>
defineProps({
  status: {
    type: String,
    required: true,
    validator: (value) => ['recommended', 'generating', 'completed', 'error', 'pending'].includes(value)
  }
})

const statusConfig = {
  recommended: { class: 'status-recommended', label: 'Recommended' },
  generating: { class: 'status-generating', label: 'Generating...' },
  completed: { class: 'status-completed', label: 'Completed' },
  error: { class: 'status-error', label: 'Error' },
  pending: { class: 'status-pending', label: 'Pending' }
}
</script>

<template>
  <span :class="statusConfig[status].class">
    {{ statusConfig[status].label }}
  </span>
</template>
```

**Usage:**
```vue
<StatusBadge :status="shot.generation_status" />
```

---

## Authentication Components

### LoginForm

**Location:** `src/components/auth/LoginForm.vue` ✅

**Description:** Email/password login with Google OAuth option.

**Features:**
- Email/password authentication
- Google OAuth integration
- Remember me checkbox
- Password reset link
- Error handling
- Loading states

**Usage:**
```vue
<script setup>
import LoginForm from '@/components/auth/LoginForm.vue'
</script>

<template>
  <div class="min-h-screen flex items-center justify-center px-4 bg-neutral-50">
    <LoginForm />
  </div>
</template>
```

---

### SignupForm

**Location:** `src/components/auth/SignupForm.vue` ✅

**Description:** User registration with validation.

**Features:**
- Full name, email, password fields
- Password confirmation
- Terms of service checkbox
- Google OAuth option
- Form validation
- Success/error messages

**Usage:**
```vue
<script setup>
import SignupForm from '@/components/auth/SignupForm.vue'
</script>

<template>
  <div class="min-h-screen flex items-center justify-center px-4 bg-neutral-50">
    <SignupForm />
  </div>
</template>
```

---

### PasswordReset

**Location:** `src/components/auth/PasswordReset.vue` ✅

**Description:** Password recovery via email.

**Features:**
- Email input
- Reset link sending
- Success confirmation
- Back to login link

**Usage:**
```vue
<script setup>
import PasswordReset from '@/components/auth/PasswordReset.vue'
</script>

<template>
  <div class="min-h-screen flex items-center justify-center px-4 bg-neutral-50">
    <PasswordReset />
  </div>
</template>
```

---

## Dashboard Components

### ProjectCard (Planned)

**Location:** `src/components/dashboard/ProjectCard.vue` (to be created)

**Description:** Project card for dashboard grid.

**Recommended Structure:**
```vue
<script setup>
const props = defineProps({
  project: {
    type: Object,
    required: true
  }
})

function getStatusColor(status) {
  const colors = {
    draft: 'badge-neutral',
    in_progress: 'badge-primary',
    completed: 'badge-success',
    archived: 'badge-neutral'
  }
  return colors[status] || 'badge-neutral'
}

function formatDate(dateString) {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}
</script>

<template>
  <div class="card-interactive">
    <div class="flex items-start justify-between mb-3">
      <h3 class="text-lg font-semibold text-neutral-900 line-clamp-1">
        {{ project.name }}
      </h3>
      <span :class="getStatusColor(project.status)">
        {{ project.status.replace('_', ' ') }}
      </span>
    </div>

    <p v-if="project.description" class="text-sm text-neutral-600 mb-4 line-clamp-2">
      {{ project.description }}
    </p>

    <div class="flex items-center justify-between text-sm text-neutral-500">
      <div class="flex items-center space-x-4">
        <span>{{ project.total_shots }} shots</span>
        <span>{{ project.total_credits_used }} credits</span>
      </div>
      <span>{{ formatDate(project.created_at) }}</span>
    </div>
  </div>
</template>
```

**Usage:**
```vue
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  <ProjectCard
    v-for="project in projects"
    :key="project.id"
    :project="project"
    @click="openProject(project.id)"
  />
</div>
```

---

### StatCard (Planned)

**Location:** `src/components/dashboard/StatCard.vue` (to be created)

**Description:** Dashboard statistics card.

**Recommended Structure:**
```vue
<script setup>
defineProps({
  title: String,
  value: [String, Number],
  icon: String,
  color: {
    type: String,
    default: 'primary'
  }
})

const colorClasses = {
  primary: 'bg-primary-100 text-primary-600',
  success: 'bg-success-100 text-success-600',
  warning: 'bg-warning-100 text-warning-600',
  error: 'bg-error-100 text-error-600'
}
</script>

<template>
  <div class="card">
    <div class="flex items-center justify-between">
      <div>
        <p class="text-sm text-neutral-600 mb-1">{{ title }}</p>
        <p class="text-2xl font-bold text-neutral-900">{{ value }}</p>
      </div>
      <div class="w-12 h-12 rounded-lg flex items-center justify-center" :class="colorClasses[color]">
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <!-- Icon based on prop -->
        </svg>
      </div>
    </div>
  </div>
</template>
```

**Usage:**
```vue
<StatCard
  title="Total Projects"
  :value="projects.length"
  icon="folder"
  color="primary"
/>
```

---

## Project Components

### CreateProjectModal (To Be Built)

**Location:** `src/components/project/CreateProjectModal.vue` (to be created)

**Description:** Multi-step form for creating new projects.

**Features:**
- Project name & description
- Script input (textarea)
- Video settings (aspect ratio, resolution)
- Language selection
- AI budget slider
- Voice settings
- Form validation

**Structure Outline:**
```vue
<template>
  <Modal :show="show" title="Create New Project" @close="$emit('close')">
    <form @submit.prevent="handleSubmit" class="space-y-6">
      <!-- Step 1: Basic Info -->
      <div>
        <label class="input-label">Project Name</label>
        <input v-model="form.name" class="input-field" required />
      </div>

      <div>
        <label class="input-label">Description (optional)</label>
        <textarea v-model="form.description" class="input-field h-20" />
      </div>

      <!-- Step 2: Script -->
      <div>
        <label class="input-label">Script</label>
        <textarea
          v-model="form.script"
          class="input-field h-40"
          placeholder="Enter your video script..."
          required
        />
        <p class="input-hint">{{ form.script.length }} characters</p>
      </div>

      <!-- Step 3: Settings -->
      <div class="grid grid-cols-2 gap-4">
        <div>
          <label class="input-label">Aspect Ratio</label>
          <select v-model="form.aspectRatio" class="input-field">
            <option value="16:9">16:9 Landscape</option>
            <option value="9:16">9:16 Portrait</option>
            <option value="1:1">1:1 Square</option>
          </select>
        </div>

        <div>
          <label class="input-label">Resolution</label>
          <select v-model="form.resolution" class="input-field">
            <option value="1080p">1080p</option>
            <option value="720p">720p</option>
            <option value="4k">4K</option>
          </select>
        </div>
      </div>

      <!-- Step 4: AI Budget -->
      <div>
        <label class="input-label">AI Budget: {{ form.aiBudget }}%</label>
        <input
          v-model="form.aiBudget"
          type="range"
          min="20"
          max="100"
          class="w-full"
        />
        <div class="flex justify-between text-xs text-neutral-500 mt-1">
          <span>Strict Style</span>
          <span>Creative Freedom</span>
        </div>
      </div>

      <!-- Error Display -->
      <div v-if="error" class="alert-error">{{ error }}</div>

      <!-- Footer -->
      <template #footer>
        <button type="button" class="btn-secondary" @click="$emit('close')">
          Cancel
        </button>
        <button type="submit" class="btn-primary" :disabled="isLoading">
          <span v-if="isLoading" class="loading-spinner mr-2"></span>
          {{ isLoading ? 'Creating...' : 'Create Project' }}
        </button>
      </template>
    </form>
  </Modal>
</template>
```

---

### ScriptInput (Planned)

**Location:** `src/components/project/ScriptInput.vue` (to be created)

**Description:** Enhanced script input with character count and formatting.

---

### ProjectSettings (Planned)

**Location:** `src/components/project/ProjectSettings.vue` (to be created)

**Description:** Project configuration editor.

---

## Production Components

### ProductionTable (To Be Built - Core Feature)

**Location:** `src/components/production/ProductionTable.vue` (to be created)

**Description:** Main production table for managing shots.

**Features:**
- Shot list display
- Bulk selection
- Real-time status updates
- Export functionality

---

### ShotRow (To Be Built)

**Location:** `src/components/production/ShotRow.vue` (to be created)

**Description:** Individual shot row in production table.

**Features:**
- Shot number & duration
- Script text display
- Prompt selector (3 alternatives)
- Generation button
- Status badge
- Audio/video players
- Action menu

**Structure Outline:**
```vue
<template>
  <tr class="hover:bg-neutral-50">
    <!-- Checkbox -->
    <td>
      <input type="checkbox" v-model="selected" />
    </td>

    <!-- Shot Number -->
    <td class="font-semibold">
      {{ shot.shot_number.toString().padStart(2, '0') }}
    </td>

    <!-- Script Text -->
    <td class="max-w-xs">
      <p class="line-clamp-2 text-sm">{{ shot.script_text }}</p>
    </td>

    <!-- Duration -->
    <td>{{ shot.duration_seconds }}s</td>

    <!-- Prompt Selector -->
    <td>
      <PromptSelector :shot="shot" />
    </td>

    <!-- Status -->
    <td>
      <StatusBadge :status="shot.generation_status" />
    </td>

    <!-- Media -->
    <td>
      <AudioPlayer v-if="shot.audio_file_url" :url="shot.audio_file_url" />
      <VideoPlayer v-if="shot.video_file_url" :url="shot.video_file_url" />
    </td>

    <!-- Actions -->
    <td>
      <button
        v-if="shot.generation_status === 'pending'"
        class="btn-primary btn-sm"
        @click="handleGenerate"
      >
        Generate
      </button>
      <button
        v-else
        class="btn-ghost btn-sm"
        @click="showActions = true"
      >
        ⋮
      </button>
    </td>
  </tr>
</template>
```

---

### PromptSelector (To Be Built)

**Location:** `src/components/production/PromptSelector.vue` (to be created)

**Description:** Dropdown for selecting AI prompt variant (A/B/C).

**Features:**
- 3 prompt alternatives
- Recommended badge on best option
- Quick preview of each prompt

---

### AudioPlayer (To Be Built)

**Location:** `src/components/production/AudioPlayer.vue` (to be created)

**Description:** Custom audio player with waveform visualization.

---

### VideoPlayer (To Be Built)

**Location:** `src/components/production/VideoPlayer.vue` (to be created)

**Description:** Custom video player with thumbnail preview.

---

## Utilities & Composables

### useN8n (To Be Built)

**Location:** `src/composables/useN8n.js` (to be created)

**Description:** n8n webhook integration composable.

**Methods:**
- `scriptBreakdown(projectId, script, aiBudget)`
- `generateAudio(shotId, voiceSettings)`
- `generateVideo(shotId, prompt)`

---

### useStorage (To Be Built)

**Location:** `src/composables/useStorage.js` (to be created)

**Description:** Supabase Storage operations.

**Methods:**
- `uploadFile(bucket, path, file)`
- `downloadFile(bucket, path)`
- `deleteFile(bucket, path)`

---

### useCredits (To Be Built)

**Location:** `src/composables/useCredits.js` (to be created)

**Description:** Credit management operations.

**Methods:**
- `deductCredits(userId, amount, reason)`
- `getBalance(userId)`
- `getTransactions(userId)`

---

## Component Priority Order

### Phase 2 (Next 2 Weeks)

1. ✅ **Common Components**
   - Modal
   - Button
   - Badge
   - StatusBadge

2. ✅ **Project Components**
   - CreateProjectModal
   - ProjectSettings

3. ✅ **Production Components** (HIGHEST PRIORITY)
   - ProductionTable
   - ShotRow
   - PromptSelector
   - AudioPlayer
   - VideoPlayer

4. ✅ **Composables**
   - useN8n
   - useStorage
   - useCredits

---

## Testing Each Component

### Manual Test Checklist

For each component:
- [ ] Renders correctly with all props
- [ ] Handles loading states
- [ ] Shows error states
- [ ] Emits events properly
- [ ] Accessible (keyboard navigation, ARIA labels)
- [ ] Responsive on mobile
- [ ] Matches design system
- [ ] Has proper transitions

---

## Component Documentation Template

When creating new components, include:

```vue
<!--
Component: ComponentName
Description: Brief description of what this component does
Props:
  - propName (Type): Description
Events:
  - eventName: Description
Usage Example:
  <ComponentName :prop="value" @event="handler" />
-->
```

---

**Component Library Version:** 1.0
**Last Updated:** January 20, 2026
**Status:** In Development 🚧
