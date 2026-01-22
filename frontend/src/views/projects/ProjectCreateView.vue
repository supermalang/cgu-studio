<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import Sidebar from '@/components/common/Sidebar.vue'
import AppHeader from '@/components/common/AppHeader.vue'

const router = useRouter()
const authStore = useAuthStore()

// Form data
const projectName = ref('')
const scriptContent = ref('')
const selectedAvatar = ref(null)
const selectedEnvironment = ref(null)
const aiEnhancementLevel = ref(65) // 20-100%
const targetAspectRatio = ref('9:16')
const targetResolution = ref('1080p')
const voiceoverLanguage = ref('en-US')

// New form fields
const projectLanguage = ref('english')
const targetPlatform = ref(null)
const targetVideoLength = ref(null)
const clipLengthMin = ref(2)
const clipLengthMax = ref(8)
const visualStyle = ref(null)
const moodTone = ref(null)
const backgroundMusicEnabled = ref(false)

// UI state
const isLoading = ref(false)
const error = ref(null)
const showAvatarBrowser = ref(false)
const showEnvironmentSettings = ref(false)

// Mock data for avatars
const avatars = ref([
  {
    id: 1,
    name: 'Mark V.',
    category: 'Casual/UGC',
    imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop',
    selected: true
  },
  {
    id: 2,
    name: 'Elena R.',
    category: 'Professional',
    imageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop',
    selected: false
  }
])

// Mock data for environments
const environments = ref([
  {
    id: 1,
    name: 'Creator Loft 01',
    imageUrl: 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=800&h=600&fit=crop',
    selected: true
  }
])

// Options for new form fields
const languageOptions = [
  { value: 'en-US', label: 'English', flag: '🇺🇸' },
  { value: 'fr-FR', label: 'French', flag: '🇫🇷' }
]

const platformOptions = [
  { value: 'tiktok', label: 'TikTok', icon: '🎵' },
  { value: 'instagram_reels', label: 'Instagram Reels', icon: '📸' },
  { value: 'youtube_shorts', label: 'YouTube Shorts', icon: '▶️' },
  { value: 'facebook', label: 'Facebook', icon: '👥' },
  { value: 'linkedin', label: 'LinkedIn', icon: '💼' }
]

const visualStyleOptions = [
  { value: 'professional', label: 'Professional', description: 'Clean, polished corporate style' },
  { value: 'casual', label: 'Casual', description: 'Relaxed, everyday vibe' },
  { value: 'cinematic', label: 'Cinematic', description: 'Film-quality, dramatic' },
  { value: 'documentary', label: 'Documentary', description: 'Factual, informative' },
  { value: 'educational', label: 'Educational', description: 'Teaching-focused, clear' }
]

const moodToneOptions = [
  { value: 'energetic', label: 'Energetic', emoji: '⚡' },
  { value: 'calm', label: 'Calm', emoji: '🌊' },
  { value: 'serious', label: 'Serious', emoji: '🎯' },
  { value: 'playful', label: 'Playful', emoji: '🎨' },
  { value: 'inspiring', label: 'Inspiring', emoji: '✨' }
]

const characterCount = computed(() => scriptContent.value.length)
const maxCharacters = 2000

const estimatedLength = computed(() => {
  // Rough estimate: ~150 words per minute, ~5 characters per word
  const words = scriptContent.value.length / 5
  const seconds = Math.round((words / 150) * 60)
  return seconds > 0 ? `~${seconds} Seconds` : '--'
})

const estimatedCost = computed(() => {
  // Rough estimate based on script length and AI level
  const baseCredits = Math.ceil(scriptContent.value.length / 100)
  const aiMultiplier = 1 + (aiEnhancementLevel.value / 100)
  return Math.ceil(baseCredits * aiMultiplier)
})

const enhancementLevelLabel = computed(() => {
  if (aiEnhancementLevel.value < 40) return 'NATURAL'
  if (aiEnhancementLevel.value > 80) return 'CINEMATIC'
  return 'BALANCED'
})

const enhancementLevelDescription = computed(() => {
  if (aiEnhancementLevel.value < 40) return 'Keep raw avatar nuances'
  if (aiEnhancementLevel.value > 80) return 'Polished studio production'
  return 'Natural with light enhancement'
})

const languageCode = computed(() => {
  return projectLanguage.value === 'french' ? 'fr-FR' : 'en-US'
})

onMounted(() => {
  // Set default selected avatar and environment
  selectedAvatar.value = avatars.value.find(a => a.selected)
  selectedEnvironment.value = environments.value.find(e => e.selected)
})

function validateForm() {
  const errors = []

  if (!projectName.value.trim()) errors.push('Project name is required')
  if (clipLengthMin.value > clipLengthMax.value) {
    errors.push('Minimum clip length cannot exceed maximum')
  }
  if (clipLengthMin.value < 2 || clipLengthMax.value > 60) {
    errors.push('Clip lengths must be between 2-60 seconds')
  }
  if (targetVideoLength.value && targetVideoLength.value < 10) {
    errors.push('Target video length must be at least 10 seconds')
  }

  return errors
}

async function handleSaveDraft() {
  const validationErrors = validateForm()
  if (validationErrors.length > 0) {
    error.value = validationErrors.join('. ')
    return
  }

  isLoading.value = true
  error.value = null

  try {
    const { data, error: createError } = await supabase
      .from('projects')
      .insert({
        user_id: authStore.user.id,
        name: projectName.value,
        slug: projectName.value.toLowerCase().replace(/[^a-z0-9]+/g, '-'),
        description: scriptContent.value.substring(0, 200),
        script: scriptContent.value,
        ai_budget_percentage: aiEnhancementLevel.value,
        target_aspect_ratio: targetAspectRatio.value,
        target_resolution: targetResolution.value,
        voiceover_language: languageCode.value,
        project_language: languageCode.value,
        target_platform: targetPlatform.value,
        target_video_length: targetVideoLength.value,
        individual_clip_length_min: clipLengthMin.value,
        individual_clip_length_max: clipLengthMax.value,
        visual_style: visualStyle.value,
        mood_tone: moodTone.value,
        background_music_enabled: backgroundMusicEnabled.value,
        status: 'draft',
        created_by: authStore.user.id,
        updated_by: authStore.user.id
      })
      .select()
      .single()

    if (createError) throw createError

    router.push(`/projects/${data.id}`)
  } catch (err) {
    console.error('Error creating project:', err)
    error.value = 'Failed to create project. Please try again.'
  } finally {
    isLoading.value = false
  }
}

async function handleGenerateVideo() {
  const validationErrors = validateForm()
  if (validationErrors.length > 0) {
    error.value = validationErrors.join('. ')
    return
  }

  if (!scriptContent.value.trim()) {
    error.value = 'Please enter script content'
    return
  }

  isLoading.value = true
  error.value = null

  try {
    const { data, error: createError } = await supabase
      .from('projects')
      .insert({
        user_id: authStore.user.id,
        name: projectName.value,
        slug: projectName.value.toLowerCase().replace(/[^a-z0-9]+/g, '-'),
        description: scriptContent.value.substring(0, 200),
        script: scriptContent.value,
        ai_budget_percentage: aiEnhancementLevel.value,
        target_aspect_ratio: targetAspectRatio.value,
        target_resolution: targetResolution.value,
        voiceover_language: languageCode.value,
        project_language: languageCode.value,
        target_platform: targetPlatform.value,
        target_video_length: targetVideoLength.value,
        individual_clip_length_min: clipLengthMin.value,
        individual_clip_length_max: clipLengthMax.value,
        visual_style: visualStyle.value,
        mood_tone: moodTone.value,
        background_music_enabled: backgroundMusicEnabled.value,
        status: 'in_progress',
        created_by: authStore.user.id,
        updated_by: authStore.user.id
      })
      .select()
      .single()

    if (createError) throw createError

    // TODO: Trigger n8n workflow for script breakdown and generation
    router.push(`/projects/${data.id}`)
  } catch (err) {
    console.error('Error creating project:', err)
    error.value = 'Failed to start video generation. Please try again.'
  } finally {
    isLoading.value = false
  }
}

function selectAvatar(avatar) {
  selectedAvatar.value = avatar
  avatars.value.forEach(a => a.selected = a.id === avatar.id)
  showAvatarBrowser.value = false
}

function selectEnvironment(environment) {
  selectedEnvironment.value = environment
  environments.value.forEach(e => e.selected = e.id === environment.id)
  showEnvironmentSettings.value = false
}
</script>

<template>
  <div class="min-h-screen bg-neutral-50">
    <Sidebar />
    <AppHeader />

    <!-- Main Content -->
    <main class="ml-64 px-6 py-8">
      <div class="max-w-6xl mx-auto">
        <!-- Breadcrumb -->
        <div class="flex items-center gap-2 mb-6 text-sm text-neutral-500">
          <router-link to="/projects" class="hover:text-neutral-900">PROJECTS</router-link>
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
          <span class="text-neutral-900 font-medium">NEW PROJECT SETUP</span>
        </div>

        <!-- Page Header -->
        <div class="flex items-center justify-between mb-8">
          <div>
            <h1 class="text-4xl font-black text-neutral-900 mb-2">Unified Project Setup</h1>
            <p class="text-base text-neutral-600">
              Configure your AI-powered UGC clip production parameters.
            </p>
          </div>

          <div class="flex items-center gap-3">
            <button
              @click="handleSaveDraft"
              :disabled="isLoading"
              class="btn-secondary"
            >
              Save Draft
            </button>
            <button
              @click="handleGenerateVideo"
              :disabled="isLoading || !projectName || !scriptContent"
              class="btn-primary flex items-center gap-2"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
              </svg>
              Generate Video
            </button>
          </div>
        </div>

        <!-- Error Message -->
        <div v-if="error" class="mb-6 bg-error-50 border border-error-200 text-error-700 px-4 py-3 rounded-lg">
          {{ error }}
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <!-- Left Column - Main Form -->
          <div class="lg:col-span-2 space-y-6">
            <!-- Script & Branding Section -->
            <div class="card">
              <div class="flex items-start gap-3 mb-6">
                <div class="w-10 h-10 rounded-lg bg-primary-100 flex items-center justify-center flex-shrink-0">
                  <svg class="w-5 h-5 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  </svg>
                </div>
                <div>
                  <h2 class="text-xl font-bold text-neutral-900">Script & Branding</h2>
                  <p class="text-sm text-neutral-600">Define your messaging and project identity.</p>
                </div>
              </div>

              <!-- Project Name -->
              <div class="mb-6">
                <label class="block text-sm font-semibold text-neutral-900 mb-2">
                  PROJECT NAME
                </label>
                <input
                  v-model="projectName"
                  type="text"
                  placeholder="Summer Promotional Campaign"
                  class="input-field"
                />
              </div>

              <!-- Script Content -->
              <div>
                <div class="flex items-center justify-between mb-2">
                  <label class="flex items-center gap-2 text-sm font-semibold text-neutral-900">
                    SCRIPT CONTENT
                    <svg class="w-4 h-4 text-neutral-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </label>
                  <span class="text-xs text-neutral-500">{{ characterCount }} / {{ maxCharacters }} CHARACTERS</span>
                </div>
                <textarea
                  v-model="scriptContent"
                  :maxlength="maxCharacters"
                  rows="8"
                  placeholder="Enter the dialogue for your AI avatar..."
                  class="input-field resize-none"
                ></textarea>
              </div>
            </div>

            <!-- Video Configuration Section -->
            <div class="card">
              <div class="flex items-start gap-3 mb-6">
                <div class="w-10 h-10 rounded-lg bg-primary-100 flex items-center justify-center flex-shrink-0">
                  <svg class="w-5 h-5 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                  </svg>
                </div>
                <div>
                  <h2 class="text-xl font-bold text-neutral-900">Video Configuration</h2>
                  <p class="text-sm text-neutral-600">Set platform, length, and clip parameters.</p>
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <!-- Language Selection -->
                <div>
                  <label class="block text-sm font-semibold text-neutral-900 mb-2">LANGUAGE</label>
                  <select v-model="projectLanguage" class="input-field">
                    <option value="english">🇺🇸 English</option>
                    <option value="french">🇫🇷 French</option>
                  </select>
                </div>

                <!-- Target Platform -->
                <div>
                  <label class="block text-sm font-semibold text-neutral-900 mb-2">TARGET PLATFORM</label>
                  <select v-model="targetPlatform" class="input-field">
                    <option :value="null">Not specified</option>
                    <option v-for="platform in platformOptions" :key="platform.value" :value="platform.value">
                      {{ platform.icon }} {{ platform.label }}
                    </option>
                  </select>
                </div>

                <!-- Target Video Length -->
                <div>
                  <label class="block text-sm font-semibold text-neutral-900 mb-2">
                    TARGET VIDEO LENGTH (SECONDS)
                  </label>
                  <input
                    v-model.number="targetVideoLength"
                    type="number"
                    min="10"
                    max="600"
                    placeholder="e.g., 60"
                    class="input-field"
                  />
                  <p class="text-xs text-neutral-500 mt-1">Leave empty for auto-calculation</p>
                </div>

                <!-- Clip Length Range -->
                <div>
                  <label class="block text-sm font-semibold text-neutral-900 mb-2">
                    INDIVIDUAL CLIP LENGTH (MIN - MAX)
                  </label>
                  <div class="flex items-center gap-2">
                    <input
                      v-model.number="clipLengthMin"
                      type="number"
                      min="2"
                      max="60"
                      class="input-field flex-1"
                      placeholder="Min"
                    />
                    <span class="text-neutral-500">–</span>
                    <input
                      v-model.number="clipLengthMax"
                      type="number"
                      min="2"
                      max="60"
                      class="input-field flex-1"
                      placeholder="Max"
                    />
                  </div>
                  <p class="text-xs text-neutral-500 mt-1">Range: 2-60 seconds per clip</p>
                </div>
              </div>
            </div>

            <!-- Creative Direction Section -->
            <div class="card">
              <div class="flex items-start gap-3 mb-6">
                <div class="w-10 h-10 rounded-lg bg-primary-100 flex items-center justify-center flex-shrink-0">
                  <svg class="w-5 h-5 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
                  </svg>
                </div>
                <div>
                  <h2 class="text-xl font-bold text-neutral-900">Creative Direction</h2>
                  <p class="text-sm text-neutral-600">Define visual style and emotional tone.</p>
                </div>
              </div>

              <!-- Visual Style Grid -->
              <div class="mb-6">
                <label class="block text-sm font-semibold text-neutral-900 mb-3">VISUAL STYLE</label>
                <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
                  <button
                    v-for="style in visualStyleOptions"
                    :key="style.value"
                    @click="visualStyle = style.value"
                    type="button"
                    :class="[
                      'p-4 rounded-lg border-2 text-left transition-all',
                      visualStyle === style.value
                        ? 'border-primary-600 bg-primary-50'
                        : 'border-neutral-200 hover:border-neutral-300'
                    ]"
                  >
                    <div class="font-bold text-neutral-900 text-sm mb-1">{{ style.label }}</div>
                    <div class="text-xs text-neutral-600">{{ style.description }}</div>
                  </button>
                </div>
              </div>

              <!-- Mood/Tone Selection -->
              <div class="mb-6">
                <label class="block text-sm font-semibold text-neutral-900 mb-3">MOOD / TONE</label>
                <div class="flex flex-wrap gap-2">
                  <button
                    v-for="mood in moodToneOptions"
                    :key="mood.value"
                    @click="moodTone = mood.value"
                    type="button"
                    :class="[
                      'px-4 py-2 rounded-lg border-2 transition-all flex items-center gap-2',
                      moodTone === mood.value
                        ? 'border-primary-600 bg-primary-50 text-primary-700'
                        : 'border-neutral-200 hover:border-neutral-300'
                    ]"
                  >
                    <span>{{ mood.emoji }}</span>
                    <span class="font-medium">{{ mood.label }}</span>
                  </button>
                </div>
              </div>

              <!-- Background Music Toggle -->
              <div>
                <label class="flex items-center gap-3 cursor-pointer">
                  <input
                    v-model="backgroundMusicEnabled"
                    type="checkbox"
                    class="w-5 h-5 text-primary-600 rounded border-neutral-300 focus:ring-primary-500"
                  />
                  <div>
                    <div class="text-sm font-semibold text-neutral-900">BACKGROUND MUSIC</div>
                    <div class="text-xs text-neutral-600">Include AI-generated background music</div>
                  </div>
                </label>
              </div>
            </div>

            <!-- AI Generation Budget -->
            <div class="card">
              <div class="flex items-start gap-3 mb-6">
                <div class="w-10 h-10 rounded-lg bg-primary-100 flex items-center justify-center flex-shrink-0">
                  <svg class="w-5 h-5 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4" />
                  </svg>
                </div>
                <div class="flex-1">
                  <div class="flex items-center justify-between mb-1">
                    <h2 class="text-xl font-bold text-neutral-900">AI Generation Budget</h2>
                    <div class="text-right">
                      <div class="text-2xl font-black text-primary-600">{{ aiEnhancementLevel }}%</div>
                      <div class="text-xs text-neutral-500 uppercase">{{ enhancementLevelLabel }}</div>
                    </div>
                  </div>
                  <p class="text-sm text-neutral-600">Adjust the AI processing budget for generation quality.</p>
                </div>
              </div>

              <!-- Slider -->
              <div class="mb-4">
                <input
                  v-model="aiEnhancementLevel"
                  type="range"
                  min="20"
                  max="100"
                  step="5"
                  class="w-full h-2 bg-neutral-200 rounded-lg appearance-none cursor-pointer accent-primary-600"
                />
              </div>

              <!-- Labels -->
              <div class="flex items-center justify-between text-xs">
                <div class="text-left">
                  <div class="font-semibold text-neutral-900 uppercase">Natural</div>
                  <div class="text-neutral-500">Keep raw avatar nuances</div>
                </div>
                <div class="text-right">
                  <div class="font-semibold text-neutral-900 uppercase">Cinematic</div>
                  <div class="text-neutral-500">Polished studio production</div>
                </div>
              </div>
            </div>
          </div>

          <!-- Right Column - Avatar, Environment, Summary -->
          <div class="space-y-6">
            <!-- Active Avatar -->
            <div class="card">
              <div class="flex items-center justify-between mb-4">
                <h3 class="text-sm font-bold text-neutral-900 uppercase">Active Avatar</h3>
                <button
                  @click="showAvatarBrowser = true"
                  class="text-sm font-medium text-primary-600 hover:text-primary-700"
                >
                  BROWSE
                </button>
              </div>

              <div v-if="selectedAvatar" class="space-y-3">
                <div
                  class="relative rounded-lg overflow-hidden bg-neutral-100"
                  style="aspect-ratio: 3/4;"
                >
                  <img
                    :src="selectedAvatar.imageUrl"
                    :alt="selectedAvatar.name"
                    class="w-full h-full object-cover"
                  />
                  <div class="absolute top-2 right-2 w-6 h-6 bg-primary-600 rounded-full flex items-center justify-center">
                    <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                    </svg>
                  </div>
                </div>
                <div>
                  <div class="font-bold text-neutral-900">{{ selectedAvatar.name }}</div>
                  <div class="text-sm text-neutral-500">{{ selectedAvatar.category }}</div>
                </div>
              </div>
            </div>

            <!-- Environment -->
            <div class="card">
              <div class="flex items-center justify-between mb-4">
                <h3 class="text-sm font-bold text-neutral-900 uppercase">Environment</h3>
                <button
                  @click="showEnvironmentSettings = true"
                  class="text-sm font-medium text-primary-600 hover:text-primary-700"
                >
                  SETTINGS
                </button>
              </div>

              <div v-if="selectedEnvironment" class="space-y-3">
                <div class="relative rounded-lg overflow-hidden bg-neutral-100 group">
                  <img
                    :src="selectedEnvironment.imageUrl"
                    :alt="selectedEnvironment.name"
                    class="w-full h-auto object-cover"
                  />
                  <div class="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black to-transparent p-3">
                    <div class="font-bold text-white text-sm">{{ selectedEnvironment.name }}</div>
                  </div>
                  <button class="absolute top-2 right-2 w-8 h-8 bg-white rounded-lg shadow-md flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                    <svg class="w-4 h-4 text-neutral-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
                    </svg>
                  </button>
                </div>
              </div>
            </div>

            <!-- Production Summary -->
            <div class="card bg-neutral-900 text-white">
              <div class="flex items-center gap-2 mb-4">
                <svg class="w-5 h-5 text-primary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                </svg>
                <h3 class="text-sm font-bold uppercase">Production Summary</h3>
              </div>

              <div class="space-y-3">
                <div v-if="targetPlatform" class="flex items-center justify-between py-2 border-b border-neutral-800">
                  <span class="text-sm text-neutral-400">Platform</span>
                  <span class="font-bold capitalize">{{ targetPlatform.replace('_', ' ') }}</span>
                </div>
                <div v-if="visualStyle" class="flex items-center justify-between py-2 border-b border-neutral-800">
                  <span class="text-sm text-neutral-400">Style</span>
                  <span class="font-bold capitalize">{{ visualStyle }}</span>
                </div>
                <div v-if="moodTone" class="flex items-center justify-between py-2 border-b border-neutral-800">
                  <span class="text-sm text-neutral-400">Mood</span>
                  <span class="font-bold capitalize">{{ moodTone }}</span>
                </div>
                <div v-if="backgroundMusicEnabled" class="flex items-center justify-between py-2 border-b border-neutral-800">
                  <span class="text-sm text-neutral-400">Music</span>
                  <span class="font-bold text-success-400">Enabled</span>
                </div>
                <div class="flex items-center justify-between py-2 border-b border-neutral-800">
                  <span class="text-sm text-neutral-400">Estimated Length</span>
                  <span class="font-bold">{{ estimatedLength }}</span>
                </div>
                <div class="flex items-center justify-between py-2 border-b border-neutral-800">
                  <span class="text-sm text-neutral-400">Cost</span>
                  <span class="font-bold text-primary-400">{{ estimatedCost }} Credits</span>
                </div>
                <div class="flex items-center justify-between py-2 border-b border-neutral-800">
                  <span class="text-sm text-neutral-400">Resolution</span>
                  <span class="font-bold">{{ targetResolution === '1080p' ? '1080×1920 (9:16)' : targetResolution }}</span>
                </div>
              </div>

              <button
                @click="handleGenerateVideo"
                :disabled="isLoading || !projectName || !scriptContent"
                class="btn-primary w-full mt-6 bg-primary-600 hover:bg-primary-700 disabled:bg-neutral-700 disabled:text-neutral-500"
              >
                START PRODUCTION
              </button>

              <p class="text-xs text-neutral-500 text-center mt-3">
                ESTIMATED WAIT: 3 MINS
              </p>
            </div>
          </div>
        </div>
      </div>
    </main>

    <!-- Avatar Browser Modal -->
    <div
      v-if="showAvatarBrowser"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
      @click.self="showAvatarBrowser = false"
    >
      <div class="bg-white rounded-lg max-w-4xl w-full p-6 max-h-[80vh] overflow-y-auto">
        <div class="flex items-center justify-between mb-6">
          <h2 class="text-2xl font-bold text-neutral-900">Select Avatar</h2>
          <button
            @click="showAvatarBrowser = false"
            class="w-8 h-8 rounded-lg hover:bg-neutral-100 flex items-center justify-center"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div class="grid grid-cols-2 md:grid-cols-3 gap-4">
          <div
            v-for="avatar in avatars"
            :key="avatar.id"
            @click="selectAvatar(avatar)"
            class="card-interactive cursor-pointer"
            :class="{ 'ring-2 ring-primary-600': avatar.selected }"
          >
            <div class="relative rounded-lg overflow-hidden bg-neutral-100 mb-3" style="aspect-ratio: 3/4;">
              <img :src="avatar.imageUrl" :alt="avatar.name" class="w-full h-full object-cover" />
              <div v-if="avatar.selected" class="absolute top-2 right-2 w-6 h-6 bg-primary-600 rounded-full flex items-center justify-center">
                <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
              </div>
            </div>
            <div class="font-bold text-neutral-900">{{ avatar.name }}</div>
            <div class="text-sm text-neutral-500">{{ avatar.category }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Custom slider styling */
input[type="range"]::-webkit-slider-thumb {
  appearance: none;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: #1313EC;
  cursor: pointer;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

input[type="range"]::-moz-range-thumb {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: #1313EC;
  cursor: pointer;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
  border: none;
}
</style>
